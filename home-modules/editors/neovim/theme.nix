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
  catppuccinCfg = config.catppuccin;
in
{
  config = mkIf cfg.enable {
    programs.nvf.settings.vim = {
      theme = {
        enable = true;
        transparent = true;
      }
      // optionalAttrs catppuccinCfg.enable {
        name = "catppuccin";
        style = catppuccinCfg.flavor;
      };
    };
  };
}
