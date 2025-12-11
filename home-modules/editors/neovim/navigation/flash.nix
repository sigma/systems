# Flash.nvim configuration
# Quick jump motions with search labels
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.utility.motion.flash-nvim = {
      enable = true;

      # LazyVim-style keymaps
      mappings = {
        jump = "s";
        treesitter = "S";
        remote = "r";
        treesitter_search = "R";
        toggle = "<c-s>";
      };
    };
  };
}
