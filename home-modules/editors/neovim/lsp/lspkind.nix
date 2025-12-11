# lspkind.nvim configuration
# VSCode-like pictograms for LSP completion items
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
    programs.nvf.settings.vim.lsp.lspkind = {
      enable = true;
      setupOpts = {
        # Show symbol and text for completion items
        mode = "symbol_text";
      };
    };
  };
}
