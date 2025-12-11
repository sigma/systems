# Lualine statusline configuration
# LazyVim-style with rounded bubble separators
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.neovim-ide;

  # Bubble/pill separators
  leftBorder = "";
  rightBorder = "";
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim.statusline.lualine = {
      enable = true;

      # Use catppuccin theme (auto will pick up from vim.theme)
      theme = "auto";

      # Section separators for bubble effect, no component separators
      sectionSeparator = {
        left = rightBorder;
        right = leftBorder;
      };
      componentSeparator = {
        left = "";
        right = "";
      };

      # Global statusline
      globalStatus = true;

      # Custom sections matching LazyVim + user preferences
      activeSection = {
        # Mode with left bubble cap
        a = [
          ''{ "mode", separator = { left = "${leftBorder}" }, right_padding = 2 }''
        ];
        # Git branch and diff (LazyVim defaults)
        b = [
          ''"branch"''
          ''{ "diff", symbols = { added = " ", modified = " ", removed = " " } }''
        ];
        # Filename and diagnostics
        c = [
          ''{ "filename", path = 1 }''
          ''{ "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } }''
        ];
        # Empty middle section
        x = [ ];
        # Progress and location
        y = [
          ''{ "progress", separator = " ", padding = { left = 1, right = 0 } }''
          ''{ "location", padding = { left = 0, right = 1 } }''
        ];
        # Clock with right bubble cap
        z = [
          ''{ function() return " " .. os.date("%R") end, separator = { right = "${rightBorder}" } }''
        ];
      };
    };
  };
}
