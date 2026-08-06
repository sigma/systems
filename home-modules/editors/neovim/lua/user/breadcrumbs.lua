-- Winbar/breadcrumbs configuration
-- Shows code context on all windows (active and inactive)

local M = {}

function M.setup(opts)
  opts = opts or {}

  local navic = require('nvim-navic')

  local function get_winbar()
    if navic.is_available() then
      local location = navic.get_location()
      if location ~= "" then
        return "%#WinBar# " .. location
      end
    end
    return ""
  end

  local function get_inactive_winbar()
    if navic.is_available() then
      local location = navic.get_location()
      if location ~= "" then
        return "%#WinBarNC# " .. location
      end
    end
    return ""
  end

  -- Set up winbar via lualine
  require('lualine').setup({
    options = {
      disabled_filetypes = {
        winbar = { 'neo-tree', 'dashboard', 'alpha', 'starter', 'toggleterm', 'TelescopePrompt' },
      },
    },
    winbar = {
      lualine_c = {
        {
          function() return get_winbar() end,
          color = { bg = 'NONE' },
        },
      },
    },
    inactive_winbar = {
      lualine_c = {
        {
          function() return get_inactive_winbar() end,
          color = { bg = 'NONE' },
        },
      },
    },
  })
end

return M
