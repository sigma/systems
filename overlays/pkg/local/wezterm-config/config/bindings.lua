local wezterm = require('wezterm')
local platform = require('utils.platform')()

local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.STD = 'SUPER'
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|SHIFT'
elseif platform.is_win or platform.is_linux then
   mod.STD = 'CTRL'
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
end

-- stylua: ignore
local keys = {
   { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER,
      action = act.QuickSelectArgs({
         label = 'open url',  
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },
   {
      key = ';',
      mods = mod.SUPER,
      action = act.QuickSelectArgs({
         action = wezterm.action_callback(function(window, pane)
            local text = window:get_selection_text_for_pane(pane)
            pane:send_paste(text)
         end),
      })
   },
   -- panes: zoom+close pane
   { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
   { key = 'w',     mods = mod.SUPER,     action = act.CloseCurrentPane({ confirm = false }) },

   -- panes: navigation
   { key = 'UpArrow',     mods = mod.SUPER, action = act.ActivatePaneDirection('Up') },
   { key = 'DownArrow',   mods = mod.SUPER, action = act.ActivatePaneDirection('Down') },
   { key = 'LeftArrow',   mods = mod.SUPER, action = act.ActivatePaneDirection('Left') },
   { key = 'RightArrow',  mods = mod.SUPER, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   -- key-tables --
   -- resizes fonts
   {
      key = 'f',
      mods = mod.SUPER_REV,
      action = act.ActivateKeyTable({
         name = 'font_resize_mode',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- resize panes
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.ActivateKeyTable({
         name = 'pane_resize_mode',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   }
}

-- stylua: ignore
local key_tables = {
   font_resize_mode = {
      { key = 'LeftArrow',      action = act.IncreaseFontSize },
      { key = 'RightArrow',     action = act.DecreaseFontSize },
      { key = 'DownArrow',      action = act.ResetFontSize },
      { key = 'UpArrow',        action = act.ResetFontSize },
      { key = 'Escape',         action = 'PopKeyTable' },
      { key = 'q',              action = 'PopKeyTable' },
   },
   pane_resize_mode = {
      { key = 'UpArrow',      action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'DownArrow',    action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'LeftArrow',    action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'RightArrow',   action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape',       action = 'PopKeyTable' },
      { key = 'q',            action = 'PopKeyTable' },
   },
}

local M = {}

M.apply_to_config = function(options, _opts)
   options.send_composed_key_when_right_alt_is_pressed = true
   options.keys = keys
   options.key_tables = key_tables
end

return M
