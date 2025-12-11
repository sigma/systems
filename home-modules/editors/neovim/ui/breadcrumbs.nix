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
      # Automatically add to lualine winbar
      lualine.winbar.enable = true;
    };
  };
}
