# Trouble.nvim configuration
# Pretty diagnostics list with quickfix/location list integration
# Also provides a symbol outline panel (v3 feature)
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

    # Trouble v3 symbol outline - pinned sidebar panel
    programs.neovim-ide.luaConfigPost."50-trouble-symbols" = ''
      vim.keymap.set("n", "<leader>co", function()
        require("trouble").toggle({
          mode = "symbols",
          win = { position = "right", size = 40 },
          focus = false,
          filter = { buf = 0 },
        })
      end, { desc = "Symbol Outline (Trouble)" })
    '';
  };
}
