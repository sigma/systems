# Lualine statusline configuration
# LazyVim-style with rounded/bubble separators
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
    programs.nvf.settings.vim.statusline.lualine = {
      enable = true;

      # Use catppuccin theme (auto will pick up from vim.theme)
      theme = "auto";

      # Rounded/bubble separators for LazyVim aesthetic
      sectionSeparator = {
        left = "";
        right = "";
      };
      componentSeparator = {
        left = "";
        right = "";
      };

      # Global statusline
      globalStatus = true;

      # Section configuration matching LazyVim defaults
      activeSection = {
        a = [
          "mode"
        ];
        b = [
          "branch"
          "diff"
        ];
        c = [
          "filename"
        ];
        x = [
          "diagnostics"
        ];
        y = [
          "filetype"
          "fileformat"
          "encoding"
        ];
        z = [
          "location"
          "progress"
        ];
      };

      inactiveSection = {
        a = [ ];
        b = [ ];
        c = [
          "filename"
        ];
        x = [ ];
        y = [ ];
        z = [
          "location"
        ];
      };
    };
  };
}
