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
    # vim-illuminate - lazy load on file open
    programs.nvf.settings.vim.lazy.plugins = {
      "vim-illuminate" = {
        package = pkgs.vimPlugins.vim-illuminate;
        event = [ "BufReadPost" "BufNewFile" ];
        after = ''
          require('illuminate').configure({
            providers = { 'lsp', 'treesitter', 'regex' },
            delay = 100,
            filetypes_denylist = {
              'neo-tree', 'NvimTree', 'TelescopePrompt', 'Trouble',
              'alpha', 'dashboard', 'help', 'lazy', 'mason',
            },
            large_file_cutoff = 2000,
            min_count_to_highlight = 2,
          })

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
