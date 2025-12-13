-- Claude Code integration
-- Setup and filetype-specific keymaps

local M = {}

function M.setup(opts)
  opts = opts or {}

  require('claudecode').setup({
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
      provider = "snacks",
    },
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
    },
  })

  -- Filetype-specific keymap for tree add (neo-tree, etc.)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "neo-tree", "NvimTree", "oil", "minifiles", "netrw" },
    callback = function()
      vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
        buffer = true,
        desc = "Add file to Claude",
      })
    end,
  })
end

return M
