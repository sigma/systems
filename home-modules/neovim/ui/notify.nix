# nvim-notify configuration
# Beautiful notification popups for Neovim
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
    programs.nvf.settings.vim.notify.nvim-notify = {
      enable = true;

      setupOpts = {
        # Use catppuccin-compatible styling
        background_colour = "#1e1e2e";
        fps = 60;
        render = "default";
        stages = "fade_in_slide_out";
        timeout = 3000;

        # Position
        top_down = true;
      };
    };
  };
}
