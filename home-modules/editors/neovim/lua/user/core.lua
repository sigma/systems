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

-- Setup auto-reload for external file changes
function M.setup_autoread()
  -- Enable autoread to allow reloading files changed outside Neovim
  vim.o.autoread = true

  -- Create autocommands to trigger checktime on various events
  local group = vim.api.nvim_create_augroup('AutoReload', { clear = true })

  -- Check for file changes when gaining focus or entering buffer
  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    group = group,
    pattern = '*',
    callback = function()
      if vim.fn.mode() ~= 'c' then
        vim.cmd('checktime')
      end
    end,
  })

  -- Notify when file changes are detected
  vim.api.nvim_create_autocmd('FileChangedShellPost', {
    group = group,
    pattern = '*',
    callback = function()
      vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.INFO)
    end,
  })
end

-- Setup borders and diagnostics (run after plugins)
function M.setup(opts)
  opts = opts or {}

  -- Setup auto-reload for external file changes
  M.setup_autoread()

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
