local wezterm = require('wezterm')

local M = {}

M.setup = function()
    wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
        return string.format('[#%d] ', tab.window_id) .. tab.window_title
  end)
end

return M
