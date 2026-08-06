# Indent guides configuration
# Visual indentation guides with scope highlighting
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
    programs.nvf.settings.vim.visuals.indent-blankline = {
      enable = true;

      setupOpts = {
        indent = {
          # Subtle indent character
          char = "│";
        };

        scope = {
          # Highlight current scope (requires treesitter)
          enabled = true;
          show_start = true;
          show_end = false;
        };

        exclude = {
          filetypes = [
            "help"
            "alpha"
            "dashboard"
            "neo-tree"
            "Trouble"
            "lazy"
            "mason"
            "notify"
            "toggleterm"
            "lazyterm"
          ];
        };
      };
    };
  };
}
