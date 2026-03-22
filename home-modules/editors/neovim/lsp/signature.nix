# Function signature help
# Uses blink.cmp's built-in signature feature (lsp-signature is incompatible)
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
    programs.nvf.settings.vim.autocomplete.blink-cmp.setupOpts = {
      signature.enabled = true;
    };
  };
}
