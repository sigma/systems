-- Core Neovim customizations
-- Borders, diagnostics, and warning suppression

local M = {}

-- Suppress specific warnings (run early, before plugins)
function M.suppress_warnings()
  local original_notify = vim.notify
  vim.notify = function(msg, level, opts)
    if type(msg) == "string" and msg:match("lspconfig.*deprecated") then
      return
    end
    return original_notify(msg, level, opts)
  end

  local original_deprecate = vim.deprecate
  vim.deprecate = function(name, alternative, version, plugin, backtrace)
    if name and name:match("lspconfig") then
      return
    end
    return original_deprecate(name, alternative, version, plugin, backtrace)
  end
end

-- Setup borders and diagnostics (run after plugins)
function M.setup(opts)
  opts = opts or {}

  -- Global border style for all floating windows
  local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
  function vim.lsp.util.open_floating_preview(contents, syntax, float_opts, ...)
    float_opts = float_opts or {}
    float_opts.border = float_opts.border or "rounded"
    return orig_util_open_floating_preview(contents, syntax, float_opts, ...)
  end

  -- Diagnostic floating windows
  vim.diagnostic.config({
    float = {
      border = "rounded",
      source = true,
    },
  })
end

return M
