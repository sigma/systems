# mini.indentscope configuration
# Animated scope indicator for the current code block
# Complements indent-blankline.nvim (static guides) with dynamic animation
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
    programs.nvf.settings.vim.lazy.plugins = {
      "mini.indentscope" = {
        package = pkgs.vimPlugins.mini-indentscope;
        event = [ "BufReadPost" "BufNewFile" ];
        load = "vim.cmd('packadd mini.indentscope')";
        after = ''
          require('mini.indentscope').setup({
            symbol = "│",
            options = { try_as_border = true },
            draw = {
              delay = 100,
              animation = require('mini.indentscope').gen_animation.none(),
            },
          })

          -- Disable in certain filetypes
          vim.api.nvim_create_autocmd("FileType", {
            pattern = {
              "help", "alpha", "dashboard", "neo-tree",
              "Trouble", "lazy", "mason", "notify",
            },
            callback = function()
              vim.b.miniindentscope_disable = true
            end,
          })
        '';
      };
    };
  };
}
