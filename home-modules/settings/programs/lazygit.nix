{
  pkgs,
  user,
  config,
  lib,
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
        showGraph = "when-maximised";
      };
      mainBranches = [
        "main"
        "master"
      ];
      pagers = [
        {
          colorArg = "always";
          pager = "${pkgs.delta}/bin/delta --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format='lazygit-edit://{path}:{line}'";
          useConfig = false;
        }
      ];
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
    os = lib.optionalAttrs (config.programs.cursor.enable || config.programs.antigravity.enable) (
      let
        editCommand =
          if config.programs.antigravity.enable then
            "${config.programs.antigravity.package}/bin/antigravity"
          else
            "${config.programs.cursor.package}/bin/cursor";
      in
      {
        edit = "${editCommand} --reuse-window -- {{filename}}";
        editAtLine = "${editCommand} --reuse-window --goto -- {{filename}}:{{line}}";
        editAtLineAndWait = "${editCommand} --reuse-window --goto --wait -- {{filename}}:{{line}}";
        editInTerminal = false;
        openDirInEditor = "${editCommand} -- {{dir}}";
      }
    );
  };
}
