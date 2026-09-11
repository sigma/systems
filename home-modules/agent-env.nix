# Environment shared by every coding agent on the machine, not just one.
#
# Mirrors the shape of ./agent-skills.nix: one registry here, contributed to by
# whichever modules have something to say, consumed by each agent's own seat.
#
#   variables : env var → value, applied inside any agent session
#   markers   : env vars whose mere presence means "an agent is driving this
#               shell"; each agent module appends its own
#
# Nothing in this module knows which agent is which, which is the point — an
# agent added later inherits the whole map by appending one marker.
#
# Why a shell hook rather than per-agent settings files: the agents do not
# agree on a declarative seat. Claude Code has `settings.env` (wired in
# ./settings/programs/claude-code.nix). Antigravity's `agy` rewrites its own
# ~/.gemini/antigravity-cli/settings.json at runtime, so the only way in is the
# imperative jq patching ./agy-hud.nix already has to do for its status line.
# What every agent *does* share is that it runs commands by spawning a shell,
# so exporting on a marker covers all of them with one mechanism.
#
# The default content is the interactive-editor lockout. An agent that trips an
# interactive VCS operation (`git commit` with no -m, `git rebase -i`,
# `jj describe`) otherwise inherits $EDITOR and launches a terminal editor with
# no terminal to drive it. `local.no-editor` fails immediately and names the
# non-interactive alternative instead. Pagers are the same class of hang: less
# without -F waits on a keypress that is never coming.
#
# This is the *legibility* layer, and it is best-effort by nature — it only
# reaches agents that spawn one of the shells below, and only when that shell
# reads its init file. The layer that actually makes the failure impossible is
# unconditional and needs no detection at all: overlays/pkg/zile.nix refuses to
# start zile without a tty, whatever the environment. An agent we have not
# added a marker for still cannot hang; it just gets the terse message rather
# than the helpful one.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.agentEnv;

  noEditor = getExe pkgs.local.no-editor;
  cat = "${pkgs.coreutils}/bin/cat";

  hasMarker = cfg.markers != [ ] && cfg.variables != { };

  # POSIX-sh test, reused verbatim by bash. `${VAR:+x}` is empty unless VAR is
  # set and non-empty, so this stays quiet under `set -u`.
  shCondition = concatMapStringsSep " || " (m: ''[ -n "''${${m}:+x}" ]'') cfg.markers;
  shExports = concatStringsSep "\n" (
    mapAttrsToList (k: v: "  export ${k}=${escapeShellArg v}") cfg.variables
  );

  fishCondition = concatMapStringsSep "; or " (m: "set -q ${m}") cfg.markers;
  fishExports = concatStringsSep "\n" (
    mapAttrsToList (k: v: "    set -gx ${k} ${escapeShellArg v}") cfg.variables
  );
in
{
  options.programs.agentEnv = {
    variables = mkOption {
      type = types.attrsOf types.str;
      example = literalExpression ''{ EDITOR = "''${pkgs.local.no-editor}/bin/no-editor"; }'';
      description = ''
        Environment applied inside any coding-agent session, keyed off
        {option}`markers`. Consumed by the shell hook here and by agents that
        offer a declarative env seat of their own.
      '';
    };

    markers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "CLAUDECODE" ];
      description = ''
        Environment variables whose presence identifies an agent session. Each
        agent module appends the variable *it* sets; a shell seeing any of them
        exports {option}`variables`.
      '';
    };
  };

  config = {
    # Claude Code sets both (verified against the 2.1.222 binary, which stamps
    # CLAUDECODE, AI_AGENT, CLAUDE_CODE_SESSION_ID and CLAUDE_CODE_CHILD_SESSION
    # into every child's environment). AI_AGENT is Claude's own variable despite
    # the vendor-neutral name — do not assume another agent sets it without
    # checking, or the guard is silently inert there.
    programs.agentEnv.markers =
      # oh-my-pi (`omp`) sets OMPCODE=1. It is not nix-managed here, so there is
      # no enable flag to gate on — and no need for one: a marker for an agent
      # that is not installed simply never appears in any environment.
      [ "OMPCODE" ]
      ++ optionals config.programs.claude-code.enable [
        "CLAUDECODE"
        "AI_AGENT"
      ];

    programs.agentEnv.variables = {
      # git resolves GIT_EDITOR > core.editor > VISUAL > EDITOR, and jj resolves
      # JJ_EDITOR > ui.editor > VISUAL/EDITOR, so an EDITOR-only override is
      # bypassed the moment either config key is set. GIT_SEQUENCE_EDITOR is the
      # one `rebase -i` reaches for.
      EDITOR = noEditor;
      VISUAL = noEditor;
      GIT_EDITOR = noEditor;
      GIT_SEQUENCE_EDITOR = noEditor;
      JJ_EDITOR = noEditor;
      SUDO_EDITOR = noEditor;

      PAGER = cat;
      GIT_PAGER = cat;
    };

    # Fish is the login shell; bash is what most agents spawn for tool calls.
    # `shellInit`, not `interactiveShellInit`: an agent's shell is not a tty.
    programs.fish.shellInit = mkIf (hasMarker && config.programs.fish.enable) (mkAfter ''
      if ${fishCondition}
      ${fishExports}
      end
    '');

    # bashrcExtra rather than initExtra: home-manager puts initExtra below the
    # interactive-shell guard, and `bash -c` from an agent never gets there.
    programs.bash.bashrcExtra = mkIf (hasMarker && config.programs.bash.enable) (mkAfter ''
      if ${shCondition}; then
      ${shExports}
      fi
    '');
  };
}
