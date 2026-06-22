{
  config,
  lib,
  pkgs,
  ...
}:
{
  enable = true;

  pager = "${pkgs.less}/bin/less -RF";

  editor = lib.mkIf config.programs.neovim-ide.enable "${config.programs.nvf.finalPackage}/bin/nvim";

  settings = {
    transparent_background = true;
  };
}
