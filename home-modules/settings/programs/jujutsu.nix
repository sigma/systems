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

  settings = {
    user = {
      name = user.name;
      email = "${profileEmail "perso"}";
    };

    ui = {
      conflict-marker-style = "git";
      default-command = "log";
      merge-editor = "mergiraf";
      movement.edit = true;
      pager = ":builtin";
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

    fix.tools.gofmt = {
      enabled = true;
      command = [ "${pkgs.go}/bin/gofmt" ];
      patterns = [ "glob:'**/*.go'" ];
    };

    fix.tools.rustfmt = {
      enabled = true;
      command = [
        "${pkgs.rustfmt}/bin/rustfmt"
        "--emit"
        "stdout"
      ];
      patterns = [ "glob:'**/*.rs'" ];
    };

    fix.tools.nixfmt = {
      enabled = true;
      command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
      patterns = [ "glob:'**/*.nix'" ];
    };

    git = {
      executable-path = "${pkgs.git}/bin/git";
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
    };

    revsets = {
      short-prefixes = "(trunk()..@)::";
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
          format_short_change_id_with_hidden_and_divergent_info(commit),
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
          if(commit.git_head(), label("git_head", "git_head()")),
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
        ui.pager = "${pkgs.delta}/bin/delta --hyperlinks";
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
