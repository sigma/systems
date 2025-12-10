# nvim-web-devicons configuration
# Provides file type icons throughout Neovim (neo-tree, bufferline, lualine, etc.)
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
    programs.nvf.settings.vim.visuals.nvim-web-devicons = {
      enable = true;
      setupOpts = {
        # Use different highlight colors per icon
        color_icons = true;
        # Let it auto-detect from background setting
        variant = null;
      };
    };
  };
}
