# programs.claude-code.settings → ~/.claude/settings.json
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Statusline script. Claude Code pipes a JSON blob on stdin; the
  # `context_window` object carries live token usage for the focused session
  # (no transcript parsing needed). See
  # https://code.claude.com/docs/en/statusline.md
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      input=$(cat)
      jq -r '
        (.model.display_name // "?")               as $model
        | (.context_window.total_input_tokens // 0)  as $used
        | (.context_window.context_window_size // 200000) as $total
        | (.context_window.used_percentage // 0)     as $pct
        | "\($model) · \(($used / 1000) | floor)k/\(($total / 1000) | floor)k ctx (\($pct | floor)%)"
      ' <<<"$input"
    '';
  };

  # WorktreeCreate / WorktreeRemove hooks. Claude Code fires these when a
  # session or subagent asks for worktree isolation (`--worktree` or
  # `isolation: "worktree"`). In a jj repo we back the "worktree" with a jj
  # *workspace* (`jj workspace add/forget`) instead of a git worktree; in a
  # plain git repo we fall back to `git worktree add`. Both hooks detect jj via
  # `jj root` on the session cwd. See
  # docs/adr/0004-jj-workspaces-for-claude-code-worktrees.md.
  #
  # WorktreeCreate *replaces* the default behaviour and chooses where the
  # worktree lives: the payload carries only a `name` slug, so we create the
  # worktree at <repo-root>/.claude/worktrees/<name> and print that path as the
  # last stdout line (non-zero exit or no path fails creation). Every diagnostic
  # goes to stderr. Because the last path component is the slug, WorktreeRemove
  # can recover the jj workspace name from basename(worktree_path).
  worktreeCreate = pkgs.writeShellApplication {
    name = "claude-worktree-create";
    runtimeInputs = [
      pkgs.jq
      pkgs.jujutsu
      pkgs.git
    ];
    text = ''
      input=$(cat)
      name=$(jq -r '.name // empty' <<<"$input")
      cwd=$(jq -r '.cwd // empty' <<<"$input")

      if [ -z "$name" ]; then
        echo "claude-worktree-create: missing name in payload" >&2
        exit 1
      fi

      # Resolve the repo root from the session cwd so the worktree lands beside
      # the repo regardless of which subdirectory the session started in. A
      # single `jj root` both detects jj and yields the root (git otherwise).
      [ -n "$cwd" ] && cd "$cwd"

      if root=$(jj --ignore-working-copy root 2>/dev/null); then
        is_jj=1
      else
        is_jj=0
        root=$(git rev-parse --show-toplevel)
      fi

      dir="$root/.claude/worktrees/$name"
      mkdir -p "$(dirname "$dir")"

      if [ "$is_jj" = 1 ]; then
        # jj repo → jj workspace. No -r: the new working copy shares the current
        # workspace's parent(s), matching git-worktree-at-HEAD semantics without
        # carrying uncommitted changes.
        jj workspace add --name "$name" "$dir" >&2
        # Give the workspace branch identity: a bookmark named after the slug at
        # the workspace @ (parity with the git fallback's `-b "$name"`). Unlike a
        # git worktree, a jj workspace shares the one commit graph, so without a
        # bookmark the agent's commits read as anonymous heads hanging off main
        # and WorktreeRemove has no handle to reconcile them. The bookmark rides
        # a subsequent `jj describe` in place (same commit), so typical work
        # stays on it. A pre-existing bookmark of that name is left untouched —
        # silently moving someone else's bookmark is worse than no bookmark.
        jj -R "$dir" bookmark create "$name" -r @ >&2 \
          || echo "claude-worktree-create: bookmark '$name' exists; workspace left unbookmarked" >&2
      else
        # Plain git repo → new branch at HEAD, detached on name collision.
        if ! git worktree add -b "$name" "$dir" HEAD >&2; then
          git worktree add --detach "$dir" HEAD >&2
        fi
      fi

      # Last stdout line must be exactly the worktree path.
      printf '%s\n' "$dir"
    '';
  };

  # WorktreeRemove performs the actual teardown. Claude Code only auto-removes
  # *its own* git worktrees; a hook-created worktree is left on disk unless this
  # hook removes it. The payload carries `worktree_path` (absolute) but no name,
  # so we recover the jj workspace name as its basename. In a jj repo:
  # `jj workspace forget` (idempotent) drops the workspace metadata, then we
  # reconcile the slug-named bookmark WorktreeCreate left behind — deleting it
  # when the work merged into trunk(), abandoning it when it's an empty leftover,
  # and keeping it (with a warning) when it's unmerged work — before deleting the
  # directory. Elsewhere we tear down any git worktree at that path and delete
  # it. Exit code is ignored by Claude Code either way.
  worktreeRemove = pkgs.writeShellApplication {
    name = "claude-worktree-remove";
    runtimeInputs = [
      pkgs.jq
      pkgs.jujutsu
      pkgs.git
    ];
    text = ''
      input=$(cat)
      worktree_path=$(jq -r '.worktree_path // empty' <<<"$input")
      cwd=$(jq -r '.cwd // empty' <<<"$input")

      if [ -z "$worktree_path" ]; then
        exit 0
      fi
      name=$(basename "$worktree_path")

      [ -n "$cwd" ] && cd "$cwd"

      if jj --ignore-working-copy root >/dev/null 2>&1; then
        # Drop the workspace metadata (and its own trailing empty @, if eligible).
        jj --ignore-working-copy workspace forget "$name" >&2 || true

        # Reconcile the workspace's branch — the bookmark WorktreeCreate set to
        # the slug. `jj workspace forget` never touches the commits a workspace
        # produced, so without this they accumulate as anonymous heads. Every
        # query is guarded: a missing bookmark makes the revset error out, and we
        # must read that as "nothing to reconcile", never as a failure. All work
        # is off the main working copy, hence --ignore-working-copy throughout.
        if [ -n "$(jj --ignore-working-copy log --no-graph -r "$name" -T change_id 2>/dev/null)" ]; then
          if [ -n "$(jj --ignore-working-copy log --no-graph -r "$name & ::trunk()" -T change_id 2>/dev/null)" ]; then
            # Fast-forward / rebase-merged: the commit is now trunk history, so
            # the bookmark is redundant. Drop the bookmark, keep the commit.
            jj --ignore-working-copy bookmark delete "$name" >&2 || true
          elif [ -z "$(jj --ignore-working-copy log --no-graph -r "$name & ~empty()" -T change_id 2>/dev/null)" ]; then
            # Divergent but empty (e.g. the change drained into a mega-merge):
            # safe to abandon, which also removes the bookmark.
            jj --ignore-working-copy abandon "$name" >&2 || true
          else
            # Divergent, non-empty: possibly unmerged work — refuse to drop it,
            # leaving the bookmark so it stays findable. Squash-merged work also
            # lands here; `bw sync` / `jj git fetch --prune` reconciles that.
            echo "claude-worktree-remove: '$name' has unmerged work; leaving it in place" >&2
          fi
        fi
        rm -rf "$worktree_path"
      else
        git -C "''${cwd:-.}" worktree remove --force "$worktree_path" >&2 2>&1 || true
        rm -rf "$worktree_path"
        git -C "''${cwd:-.}" worktree prune >&2 2>&1 || true
      fi
      exit 0
    '';
  };
in
{
  # Gate on enable so hosts without claude-code don't emit a stray settings.json.
  settings = lib.mkIf config.programs.claude-code.enable {
    # Prefer our own curated skillsets (see ./claude-skills.nix) over the CLI's
    # bundled ones; bundled built-ins stay typable as slash commands but are
    # hidden from the model, avoiding name clashes with our skills (e.g.
    # code-review).
    disableBundledSkills = true;

    # Driven from Nix, not claude.ai — turn off the remote-control channel,
    # claude.ai MCP connectors, and the Artifact tool that publishes session
    # output to claude.ai.
    disableRemoteControl = true;
    disableClaudeAiConnectors = true;
    disableArtifact = true;

    # Official LSP plugins for the languages we work in.
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
      "clangd-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
    };

    # Keep extended thinking on by default.
    alwaysThinkingEnabled = true;

    # Default adaptive reasoning effort (low | medium | high | xhigh);
    # `max`/`ultracode` are session-only. Persisted across sessions.
    effortLevel = "medium";

    # Don't prompt when entering dangerous (bypass-permissions) mode.
    skipDangerousModePermissionPrompt = true;

    # Show the focused session's model and live context-window token usage.
    statusLine = {
      type = "command";
      command = lib.getExe statusline;
      padding = 0;
    };

    # Back worktree isolation with jj workspaces in jj repos (git-worktree
    # fallback elsewhere). These events take no matcher. Create can block
    # (generous timeout guards against a cold FS, though jj workspace add is
    # sub-second); remove is fire-and-forget cleanup.
    hooks = {
      WorktreeCreate = [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe worktreeCreate;
              timeout = 120;
            }
          ];
        }
      ];
      WorktreeRemove = [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe worktreeRemove;
            }
          ];
        }
      ];
    };
  };
}
