-- lazygit.nvim configuration
-- Toggle lazygit in a floating terminal window

local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Lazygit configuration (via globals)
  vim.g.lazygit_floating_window_use_plenary = 0
  vim.g.lazygit_floating_window_border_chars = {'╭','─', '╮', '│', '╯','─', '╰', '│'}

  -- Lazygit keymaps (LazyVim-style)
  vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
  vim.keymap.set("n", "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", { desc = "LazyGit Current File" })
end

return M
