# LSP keymaps
# LazyVim-style LSP keybindings
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
    programs.nvf.settings.vim.keymaps = [
      # Go to definition
      {
        key = "gd";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
        desc = "Go to definition";
      }
      # Go to declaration
      {
        key = "gD";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
        desc = "Go to declaration";
      }
      # Go to references
      {
        key = "gr";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.references()<cr>";
        desc = "Go to references";
      }
      # Go to implementation
      {
        key = "gI";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
        desc = "Go to implementation";
      }
      # Go to type definition
      {
        key = "gy";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
        desc = "Go to type definition";
      }
      # Hover documentation
      {
        key = "K";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.hover()<cr>";
        desc = "Hover documentation";
      }
      # Signature help
      {
        key = "gK";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
        desc = "Signature help";
      }
      # Code action
      {
        key = "<leader>ca";
        mode = [ "n" "v" ];
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        desc = "Code action";
      }
      # Rename
      {
        key = "<leader>cr";
        mode = [ "n" ];
        action = "<cmd>lua vim.lsp.buf.rename()<cr>";
        desc = "Rename symbol";
      }
      # Format
      {
        key = "<leader>cf";
        mode = [ "n" "v" ];
        action = "<cmd>lua vim.lsp.buf.format({ async = true })<cr>";
        desc = "Format";
      }
      # Line diagnostics
      {
        key = "<leader>cd";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.open_float()<cr>";
        desc = "Line diagnostics";
      }
      # Next diagnostic
      {
        key = "]d";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        desc = "Next diagnostic";
      }
      # Previous diagnostic
      {
        key = "[d";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        desc = "Previous diagnostic";
      }
      # Next error
      {
        key = "]e";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>";
        desc = "Next error";
      }
      # Previous error
      {
        key = "[e";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>";
        desc = "Previous error";
      }
      # Next warning
      {
        key = "]w";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })<cr>";
        desc = "Next warning";
      }
      # Previous warning
      {
        key = "[w";
        mode = [ "n" ];
        action = "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })<cr>";
        desc = "Previous warning";
      }
    ];
  };
}
