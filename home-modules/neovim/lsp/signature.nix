# lsp-signature.nvim configuration
# Show function signature help as you type
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
    programs.nvf.settings.vim.lsp.lspSignature = {
      enable = true;
      setupOpts = {
        # Floating window border
        handler_opts.border = "rounded";
        # Show hint in a floating window, not virtual text
        floating_window = true;
        # Highlight the current parameter
        hi_parameter = "LspSignatureActiveParameter";
        # Toggle signature with <C-k>
        toggle_key = "<C-k>";
        # Move to next/prev parameter with <C-f>/<C-d>
        move_cursor_key = null;
      };
    };
  };
}
