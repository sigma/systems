# vim-illuminate configuration
# Highlight word under cursor throughout the document
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
      vim-illuminate = {
        package = pkgs.vimPlugins.vim-illuminate;
        setup = ''
          require('illuminate').configure({
            -- Providers to use for highlighting
            providers = {
              'lsp',
              'treesitter',
              'regex',
            },
            -- Delay in milliseconds
            delay = 100,
            -- Filetypes to ignore
            filetypes_denylist = {
              'neo-tree',
              'NvimTree',
              'TelescopePrompt',
              'Trouble',
              'alpha',
              'dashboard',
              'help',
              'lazy',
              'mason',
            },
            -- Don't highlight large files
            large_file_cutoff = 2000,
            large_file_overrides = nil,
            -- Minimum word length
            min_count_to_highlight = 2,
          })

          -- LazyVim-style keymaps
          vim.keymap.set('n', ']]', function()
            require('illuminate').goto_next_reference(false)
          end, { desc = 'Next reference' })

          vim.keymap.set('n', '[[', function()
            require('illuminate').goto_prev_reference(false)
          end, { desc = 'Previous reference' })
        '';
      };
    };
  };
}
