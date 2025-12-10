# Theme configuration
# Catppuccin frappe variant
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
    programs.nvf.settings.vim = {
      theme = {
        enable = true;
        name = "catppuccin";
        style = "frappe";
      };
    };
  };
}
