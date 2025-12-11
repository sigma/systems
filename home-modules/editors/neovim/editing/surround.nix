# Surround configuration
# Add/change/delete surrounding pairs
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
    programs.nvf.settings.vim.utility.surround = {
      enable = true;
      # Use classic ys/ds/cs keybindings
      useVendoredKeybindings = false;
    };
  };
}
