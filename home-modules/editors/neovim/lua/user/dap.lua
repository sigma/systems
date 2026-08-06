-- DAP (Debug Adapter Protocol) sign configuration
-- Sets up breakpoint and stopped icons

local M = {}

function M.setup(opts)
  opts = opts or {}
  local icons = opts.icons or {}

  -- DAP breakpoint signs
  vim.fn.sign_define("DapBreakpoint", {
    text = icons.breakpoint or "●",
    texthl = "DapBreakpoint"
  })
  vim.fn.sign_define("DapBreakpointCondition", {
    text = icons.breakpointCondition or "●",
    texthl = "DapBreakpointCondition"
  })
  vim.fn.sign_define("DapBreakpointRejected", {
    text = icons.breakpointRejected or "●",
    texthl = "DapBreakpointRejected"
  })
  vim.fn.sign_define("DapLogPoint", {
    text = icons.logPoint or "◆",
    texthl = "DapLogPoint"
  })
  vim.fn.sign_define("DapStopped", {
    text = icons.stopped or "→",
    texthl = "DapStopped",
    linehl = "DapStoppedLine"
  })
end

return M
