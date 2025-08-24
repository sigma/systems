{
  user,
  pkgs,
  ...
}: let
  profileEmail = name: let
    prof = builtins.head (builtins.filter (prof: prof.name == name) user.profiles);
  in
    builtins.head prof.emails;
in {
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
      movement = "edit";
      pager = ":builtin";
    };

    merge-tools.cursor = {
      program = "cursor";
      merge-args = ["--wait" "--merge" "$left" "$right" "$base" "$output"];
      merge-tool-edits-conflict-markers = true;
      conflict-marker-style = "git";
      diff-args = ["--diff" "$left" "$right" "--wait"];
      diff-invocation-mode = "file-by-file";
      edit-args = [];
    };

    fix.tools.gofmt = {
      enabled = true;
      command = ["gofmt"];
      patterns = ["glob:'**/*.go'"];
    };

    fix.tools.rustfmt = {
      enabled = true;
      command = ["rustfmt" "--emit" "stdout"];
      patterns = ["glob:'**/*.rs'"];
    };

    git = {
      executable-path = "${pkgs.git}/bin/git";
      push-new-bookmarks = true;
      private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
    };

    signing = {
      behavior = "own";
      backend = "ssh";
    };

    aliases = {
      l = ["log" "-r" "(trunk()..@):: | (trunk()..@)-"];
    };

    revsets = {
      short-prefixes = "(trunk()..@)::";
    };

    template-aliases = {
      format_short_id = "id.shortest(8)";
    };

    templates = {
      config_list = "builtin_config_list_detailed";
      draft_commit_description = ''
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
      git_push_bookmark = ''"${user.githubHandle}/push-" ++ change_id.short()'';
    };
  };

  scopes = {
    work = {
      repositories = [
        "~/src/github.com/subzerolabs"
      ];

      settings = {
        user.email = user.email;

        revset-aliases.work = "heads(::@ ~ description(exact:''))::";

        aliases.wip = ["log" "-r" "work"];
      };
    };

    delta = {
      commands = ["diff" "show"];

      settings = {
        ui.pager = "${pkgs.delta}/bin/delta";
        ui.diff-formatter = ":git";
      };
    };
  };
}
