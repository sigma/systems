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
    # mini.bufremove - lazy load after UI is ready
    programs.nvf.settings.vim.lazy.plugins = {
      "mini.bufremove" = {
        package = pkgs.vimPlugins.mini-nvim;
        event = [ "BufReadPost" "BufNewFile" ];
        # Custom load function since package is mini.nvim but we only want mini.bufremove
        load = "vim.cmd('packadd ' .. name)";
        after = ''
          require('mini.bufremove').setup({
            set_vim_settings = true,
            silent = false,
          })

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
