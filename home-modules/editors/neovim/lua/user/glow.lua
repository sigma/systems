-- glow.nvim configuration
-- Terminal-based markdown preview

local M = {}

function M.setup(opts)
  opts = opts or {}

  require('glow').setup({
    glow_path = opts.glow_path or "glow",
    border = "rounded",
  })
end

return M
