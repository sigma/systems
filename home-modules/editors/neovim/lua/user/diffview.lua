-- diffview.nvim keymaps
-- Cycle through diffs, file history, merge tool

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Diffview keymaps (LazyVim-style under <leader>g prefix)
  vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
  vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
  vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview File History" })
  vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview Current File History" })
end

return M
