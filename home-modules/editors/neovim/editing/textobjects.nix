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
    programs.nvf.settings.vim.extraPlugins = {
      mini-ai = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.ai').setup({
            -- Number of lines within which textobject is searched
            n_lines = 500,

            -- Custom textobjects
            custom_textobjects = {
              -- Function (treesitter-based)
              f = require('mini.ai').gen_spec.treesitter({
                a = '@function.outer',
                i = '@function.inner',
              }),
              -- Class (treesitter-based)
              c = require('mini.ai').gen_spec.treesitter({
                a = '@class.outer',
                i = '@class.inner',
              }),
              -- Block (treesitter-based)
              o = require('mini.ai').gen_spec.treesitter({
                a = { '@block.outer', '@conditional.outer', '@loop.outer' },
                i = { '@block.inner', '@conditional.inner', '@loop.inner' },
              }),
              -- Argument/parameter
              a = require('mini.ai').gen_spec.treesitter({
                a = '@parameter.outer',
                i = '@parameter.inner',
              }),
            },

            -- Module mappings
            mappings = {
              -- Main textobject prefixes
              around = 'a',
              inside = 'i',

              -- Next/previous textobject
              around_next = 'an',
              inside_next = 'in',
              around_last = 'al',
              inside_last = 'il',

              -- Move cursor to corresponding edge
              goto_left = 'g[',
              goto_right = 'g]',
            },
          })
        '';
      };
    };
  };
}
