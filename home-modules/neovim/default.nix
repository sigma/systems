# nvf-based Neovim configuration
# Aims to replicate LazyVim experience
#
# See docs/nvf-lazyvim-roadmap.md for the full plan
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  imports = [
    ./core.nix
    ./theme.nix
    ./keymaps.nix
    ./ui
  ];

  options.programs.neovim-ide = {
    enable = mkEnableOption "LazyVim-like Neovim configuration via nvf";
  };

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;

      settings.vim = {
        # Use vi/vim aliases
        viAlias = true;
        vimAlias = true;

        # Enable visual features
        visuals = {
          nvim-scrollbar.enable = true;
          nvim-cursorline.enable = true;
        };

        # Enable treesitter for syntax highlighting
        treesitter = {
          enable = true;
          indent.enable = true;
          highlight.enable = true;
        };
      };
    };
  };
}
