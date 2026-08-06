# Which-key configuration
# Keybinding hints popup
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
    programs.nvf.settings.vim.binds.whichKey = {
      enable = true;

      setupOpts = {
        # Modern popup style
        preset = "modern";

        # Show warnings about mapping issues
        notify = true;

        # Disable icons to avoid mini.icons/devicons compatibility issues
        icons = {
          mappings = false;
          rules = false;
        };

        # Custom label replacements
        replace = {
          "<space>" = "SPC";
          "<leader>" = "SPC";
          "<cr>" = "RET";
          "<tab>" = "TAB";
        };
      };

      # Register group labels for leader key menus
      register = {
        "<leader>b" = "+buffer";
        "<leader>c" = "+code";
        "<leader>f" = "+file/find";
        "<leader>g" = "+git";
        "<leader>s" = "+search";
        "<leader>u" = "+ui";
        "<leader>w" = "+windows";
        "<leader>x" = "+diagnostics";
        "<leader><tab>" = "+tabs";
      };
    };
  };
}
