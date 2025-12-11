# mini.bufremove configuration
# Better buffer deletion without messing up window layout
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
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.extraPlugins = {
      mini-bufremove = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.bufremove').setup({
            -- Whether to set vim.cmd.bdelete/bwipeout to use mini.bufremove
            set_vim_settings = true,
            -- Preserve window layout when deleting a buffer
            silent = false,
          })

          -- LazyVim-style keymaps for buffer deletion
          vim.keymap.set('n', '<leader>bd', function()
            require('mini.bufremove').delete(0, false)
          end, { desc = 'Delete buffer' })

          vim.keymap.set('n', '<leader>bD', function()
            require('mini.bufremove').delete(0, true)
          end, { desc = 'Delete buffer (force)' })
        '';
      };
    };
  };
}
