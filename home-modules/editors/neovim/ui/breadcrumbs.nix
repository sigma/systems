# nvim-navic breadcrumbs configuration
# Shows code context (function/class/etc) in the winbar
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
    programs.nvf.settings.vim.ui.breadcrumbs = {
      enable = true;
      # Use nvim-navic as the source
      source = "nvim-navic";
      # Disable nvf's default winbar, we'll configure it manually
      lualine.winbar.enable = false;
    };

    # Winbar configuration (Lua module)
    programs.neovim-ide.luaConfigPost."15-winbar" = ''
      require('user.breadcrumbs').setup()
    '';
  };
}
