-- Markdown preview keymaps
-- Browser-based markdown preview

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Markdown preview keymaps
  vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", { desc = "Markdown Preview" })
  vim.keymap.set("n", "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", { desc = "Markdown Preview Stop" })
  vim.keymap.set("n", "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview Toggle" })
end

return M
