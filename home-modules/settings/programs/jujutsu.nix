{
  user,
  machine,
  pkgs,
  config,
  lib,
  ...
}:
let
  profileEmail =
    name:
    let
      prof = builtins.head (builtins.filter (prof: prof.name == name) user.profiles);
    in
    builtins.head prof.emails;
in
{
  enable = true;
  ediff = false;

  # jj and jjui both ship in the toolbox's vcs-toolchain bundle
  # (home-modules/default.nix), so this module is here for the config it
  # generates — installing them again would collide on `bin/jj` / `bin/jjui`.
  #
  # `package` can't be null despite being nullable: home-manager reads its
  # version to pick the config-file path. Pointing it at the bundle keeps that
  # working (buildEnv dedups the identical store path) and the bundle's "12"
  # reads as >= 0.29.0, which is the right branch for the jj it ships (0.44).
  package = pkgs.toolbox.vcs-toolchain;
  enableUI = false;

  settings = {
    user = {
      inherit (user) name;
      email = "${profileEmail "perso"}";
    };

    ui = {
      conflict-marker-style = "git";
      default-command = "log";
      merge-editor = "mergiraf";
      movement.edit = true;
      pager = ":builtin";
    };

    merge-tools.antigravity = lib.optionalAttrs config.programs.antigravity.enable {
      program = "${config.programs.antigravity.package}/bin/antigravity";
      merge-args = [
        "--wait"
        "--merge"
        "$left"
        "$right"
        "$base"
        "$output"
      ];
      merge-tool-edits-conflict-markers = true;
      conflict-marker-style = "git";
      diff-args = [
        "--diff"
        "$left"
        "$right"
        "--wait"
      ];
      diff-invocation-mode = "file-by-file";
      edit-args = [ ];
    };

    merge-tools.cursor = lib.optionalAttrs config.programs.cursor.enable {
      program = "${config.programs.cursor.package}/bin/cursor";
      merge-args = [
        "--wait"
        "--merge"
        "$left"
        "$right"
        "$base"
        "$output"
      ];
      merge-tool-edits-conflict-markers = true;
      conflict-marker-style = "git";
      diff-args = [
        "--diff"
        "$left"
        "$right"
        "--wait"
      ];
      diff-invocation-mode = "file-by-file";
      edit-args = [ ];
    };

    fix.tools = {
      gofmt = {
        enabled = true;
        command = [ "${pkgs.go}/bin/gofmt" ];
        patterns = [ "glob:'**/*.go'" ];
      };

      rustfmt = {
        enabled = true;
        command = [
          "${pkgs.rustfmt}/bin/rustfmt"
          "--emit"
          "stdout"
        ];
        patterns = [ "glob:'**/*.rs'" ];
      };

      nixfmt = {
        enabled = true;
        command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        patterns = [ "glob:'**/*.nix'" ];
      };
    };

    git = {
      # Same git jj gets on PATH — the vcs-toolchain bundle's, not nixpkgs'.
      executable-path = "${pkgs.toolbox.vcs-toolchain}/bin/git";
      private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
    };

    signing = lib.optionalAttrs (machine.signingKey != null) {
      key = machine.signingKey;
      behavior = "own";
      backend = "ssh";
    };

    aliases = {
      l = [
        "log"
        "-r"
        "(trunk()..@):: | (trunk()..@)-"
      ];
      rebase-all = [
        "rebase"
        "-s"
        "roots(present(@) | ancestors(immutable_heads().., 1))"
        "-d"
        "trunk()"
      ];
      tug = [
        "bookmark"
        "advance"
      ];
      # Compound aliases via `util exec` — jj's own alias system can't chain
      # subcommands, so shell out and re-enter jj.
      pull = [
        "util"
        "exec"
        "--"
        "sh"
        "-c"
        "jj git fetch && jj rebase-all"
      ];
      push = [
        "util"
        "exec"
        "--"
        "sh"
        "-c"
        "jj tug && jj git push"
      ];
      # Open the unpushed-changes revset in hunk's TUI. Only defined
      # when programs.hunk is enabled, and pinned to the wrapped
      # binary so it doesn't depend on hunk being on PATH.
      review = lib.mkIf config.programs.hunk.enable [
        "util"
        "exec"
        "--"
        "${config.programs.hunk.finalPackage}/bin/hunk"
        "show"
        "pending()"
      ];
    };

    revset-aliases = {
      # Treat beadwork commits and the `entire` tool's bookmarks as immutable.
      # This keeps them out of the default log (which shows the mutable set,
      # immutable_heads()..): marking an entire/* bookmark tip immutable
      # propagates to its ancestors, hiding the whole checkpoint chain.
      "immutable_heads()" =
        ''builtin_immutable_heads() | author(exact:"beadwork") | bookmarks(glob:"entire/*")'';
      "last_change()" = "latest(ancestors(@) & ~empty())";
      # Everything reachable from @ that isn't already on a remote —
      # i.e., the changes that haven't been pushed yet.
      "pending()" = "remote_bookmarks()..@";
    };

    revsets = {
      short-prefixes = "(trunk()..@)::";
      bookmark-advance-to = "last_change()";
    };

    template-aliases = {
      format_short_id = "id.shortest(8)";

      commit_description_verbose = ''
        concat(
          coalesce(description, default_commit_description, "\n"),
          surround(
            "\nJJ: This commit contains the following changes:\n", "",
            indent("JJ:     ", diff.stat(72)),
          ),
          "\nJJ: ignore-rest\n",
          diff.git(),
        )
      '';

      user_auto_bookmark = ''"${user.githubHandle}/push-" ++ change_id.short()'';

      "user_format_short_commit_header(commit)" = ''
        separate(" ",
          format_short_change_id_with_change_offset(commit),
          if(description,
            label("description title", description.first_line()),
            label(if(empty, "empty"), description_placeholder),
          ),
          if(empty, label("empty", "(empty)")),
          format_short_commit_id(commit.commit_id()),
          if(commit.conflict(), label("conflict", "conflict")),
        )
      '';

      "user_format_short_commit_meta(commit)" = ''
        separate(" ",
          commit.bookmarks(),
          commit.tags(),
          format_short_signature(commit.author()),
          format_timestamp(commit_timestamp(commit)),
          commit.working_copies(),
          if(commit.contained_in('first_parent(@)'), label("git_head", "git_head()")),
          if(config("ui.show-cryptographic-signatures").as_boolean(),
            format_short_cryptographic_signature(commit.signature())),
        )
      '';

      "user_log_compact" = ''
        if(root,
          format_root_commit(self),
          label(if(current_working_copy, "working_copy"),
            concat(
              user_format_short_commit_header(self),
              "\n  ",
              user_format_short_commit_meta(self),
              "\n",
            ),
          )
        )
      '';
      "user_log_comfortable" = "user_log_compact ++ '\n'";
    };

    templates = {
      config_list = "builtin_config_list_detailed";
      draft_commit_description = "commit_description_verbose";
      git_push_bookmark = "user_auto_bookmark";
      log = "user_log_comfortable";
    };
  };

  scopes = {
    delta = {
      commands = [
        "diff"
        "show"
      ];

      settings = {
        # delta from the vcs-toolchain bundle, so the closure carries one.
        ui.pager = "${pkgs.toolbox.vcs-toolchain}/bin/delta --hyperlinks";
        ui.diff-formatter = ":git";
      };
    };

    personal = {
      repositories = [
        "~/src/github.com/${user.githubHandle}"
      ];
      settings = {
        remotes.origin = {
          auto-track-bookmarks = "glob:*";
        };
      };
    };
  };
}
