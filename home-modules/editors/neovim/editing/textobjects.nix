# mini.ai configuration
# Enhanced text objects with treesitter support
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
    # mini.ai - lazy load after UI is ready (text objects)
    programs.nvf.settings.vim.lazy.plugins = {
      "mini.ai" = {
        package = pkgs.vimPlugins.mini-nvim;
        event = [ "BufReadPost" "BufNewFile" ];
        # Package is mini-nvim, not mini.ai
        load = "vim.cmd('packadd mini.nvim')";
        after = ''
          local ai = require('mini.ai')
          local gen_spec = ai.gen_spec
          ai.setup({
            n_lines = 500,
            custom_textobjects = {
              f = gen_spec.treesitter({
                a = '@function.outer',
                i = '@function.inner',
              }),
              c = gen_spec.treesitter({
                a = '@class.outer',
                i = '@class.inner',
              }),
              o = gen_spec.treesitter({
                a = { '@block.outer', '@conditional.outer', '@loop.outer' },
                i = { '@block.inner', '@conditional.inner', '@loop.inner' },
              }),
              a = gen_spec.treesitter({
                a = '@parameter.outer',
                i = '@parameter.inner',
              }),
            },
            mappings = {
              around = 'a',
              inside = 'i',
              around_next = 'an',
              inside_next = 'in',
              around_last = 'al',
              inside_last = 'il',
              goto_left = 'g[',
              goto_right = 'g]',
            },
          })
        '';
      };
    };
  };
}
