# Alpha-nvim dashboard configuration
# Start screen with quick actions
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
    programs.nvf.settings.vim.dashboard.alpha = {
      enable = true;
      theme = "dashboard";
    };
  };
}
