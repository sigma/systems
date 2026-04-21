# nvim-treesitter-textobjects configuration
# Language-aware motions: jump to functions/classes, swap arguments
# Complements mini.ai (which handles text object selection)
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
    programs.nvf.settings.vim.treesitter.textobjects = {
      enable = false; # blocked: nvf's lzn-auto-require can't resolve nvim-treesitter.config (still broken as of nvf f4de19e1)

      setupOpts = {
        # Jump to next/previous function, class, parameter
        move = {
          enable = true;
          set_jumps = true;
          goto_next_start = {
            "]f" = "@function.outer";
            "]c" = "@class.outer";
            "]a" = "@parameter.inner";
          };
          goto_next_end = {
            "]F" = "@function.outer";
            "]C" = "@class.outer";
          };
          goto_previous_start = {
            "[f" = "@function.outer";
            "[c" = "@class.outer";
            "[a" = "@parameter.inner";
          };
          goto_previous_end = {
            "[F" = "@function.outer";
            "[C" = "@class.outer";
          };
        };

        # Swap arguments/parameters
        swap = {
          enable = true;
          swap_next = {
            "<leader>sa" = "@parameter.inner";
          };
          swap_previous = {
            "<leader>sA" = "@parameter.inner";
          };
        };
      };
    };
  };
}
