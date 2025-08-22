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

    ui.default-command = "log";
    ui.movement = "edit";

    fix.tools.rustfmt = {
      enabled = true;
      command = ["rustfmt" "--emit" "stdout"];
      patterns = ["glob:'**/*.rs'"];
    };

    git.push-new-bookmarks = true;
    git.private-commits = "description(glob:'wip:*') | description(glob:'private:*')";

    signing.behavior = "own";
    signing.backend = "ssh";

    aliases.l = ["log" "-r" "(main..@):: | (main..@)-"];
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

    log = {
      commands = ["log"];

      settings = {
        ui.pager = ":builtin";
      };
    };

    status = {
      commands = ["status"];

      settings = {
        ui.paginate = "never";
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
