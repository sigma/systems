{pkgs, ...}: {
  enable = true;
  settings = {
    git = {
      log = {
        order = "topo-order";
        showGraph = "when-maximized";
      };
      mainBranches = ["main" "master"];
      paging = {
        colorArg = "always";
        pager = "${pkgs.delta}/bin/delta --paging=never -n -s";
        useConfig = false;
      };
      parseEmoji = true;
      skipHookPrefix = "WIP";
    };
    gui = {
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
