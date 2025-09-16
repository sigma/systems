{
  pkgs,
  user,
  ...
}:
let
  ownColor = "red";
in
{
  enable = true;
  settings = {
    git = {
      log = {
        order = "topo-order";
        showGraph = "when-maximized";
      };
      mainBranches = [
        "main"
        "master"
      ];
      paging = {
        colorArg = "always";
        pager = "${pkgs.delta}/bin/delta --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format='lazygit-edit://{path}:{line}'";
        useConfig = false;
      };
      parseEmoji = true;
      skipHookPrefix = "WIP";
    };
    gui = {
      authorColors = {
        "${user.name}" = ownColor;
      };
      branchColors = {
        "${user.githubHandle}" = ownColor;
      };
      nerdFontsVersion = "3";
    };
    os = {
      edit = "cursor --reuse-window -- {{filename}}";
      editAtLine = "cursor --reuse-window --goto -- {{filename}}:{{line}}";
      editAtLineAndWait = "cursor --reuse-window --goto --wait -- {{filename}}:{{line}}";
      editInTerminal = false;
      openDirInEditor = "cursor -- {{dir}}";
    };
  };
}
