# Trouble.nvim configuration
# Pretty diagnostics list with quickfix/location list integration
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
    programs.nvf.settings.vim.lsp.trouble = {
      enable = true;

      # LazyVim-style keymaps
      mappings = {
        workspaceDiagnostics = "<leader>xX";
        documentDiagnostics = "<leader>xx";
        lspReferences = "<leader>xr";
        quickfix = "<leader>xQ";
        locList = "<leader>xL";
        symbols = "<leader>cs";
      };
    };
  };
}
