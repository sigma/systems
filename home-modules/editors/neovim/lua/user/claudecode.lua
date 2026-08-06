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
      open_in_current_tab = true,
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

  -- Auto-enter terminal mode when focusing the Claude terminal
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "term://*",
    callback = function()
      -- Only auto-enter insert mode for Claude terminal buffers
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname:match("claude") then
        vim.cmd("startinsert")
      end
    end,
  })
end

return M
