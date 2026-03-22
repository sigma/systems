# render-markdown.nvim configuration
# Inline markdown rendering with headings, code blocks, tables, checkboxes
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
      "render-markdown.nvim" = {
        package = pkgs.vimPlugins.render-markdown-nvim;
        ft = [
          "markdown"
          "norg"
          "org"
        ];
        after = ''
          require('render-markdown').setup({
            file_types = { "markdown", "norg", "org" },
          })
        '';
      };
    };
  };
}
