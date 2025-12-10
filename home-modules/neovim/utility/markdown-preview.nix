# markdown-preview.nvim configuration
# Live preview for Markdown files in the browser
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
    programs.nvf.settings.vim.utility.preview.markdownPreview = {
      enable = true;
      # Don't auto-start, use keybinding instead
      autoStart = false;
      # Auto-close when leaving markdown buffer
      autoClose = true;
      # Only update on save for better performance
      lazyRefresh = true;
      # Only for markdown files
      filetypes = [ "markdown" ];
    };

    # Add keymaps for markdown preview
    programs.neovim-ide.luaConfigPost."60-markdown-preview-keymaps" = ''
      -- Markdown preview keymaps
      vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", { desc = "Markdown Preview" })
      vim.keymap.set("n", "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", { desc = "Markdown Preview Stop" })
      vim.keymap.set("n", "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview Toggle" })
    '';
  };
}
