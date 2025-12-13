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

-- Smart splits integration: detect if pane is running vim/neovim
local function is_vim(pane)
   local process_info = pane:get_foreground_process_info()
   local process_name = process_info and process_info.name

   if process_name then
      return process_name:find('n?vim') ~= nil
   end

   -- Fallback: check pane title
   local title = pane:get_title()
   return title:find('n?vim') ~= nil
end

-- Conditionally send keys to vim or activate pane direction
-- We use Alt+Ctrl+Shift+hjkl as a unique sequence that Neovim can recognize
local direction_to_key = {
   Left = 'h',
   Right = 'l',
   Up = 'k',
   Down = 'j',
}

local function smart_split_nav(direction)
   return wezterm.action_callback(function(window, pane)
      if is_vim(pane) then
         -- Send Alt+Ctrl+Shift+hjkl to vim (mapped to smart-splits)
         local key = direction_to_key[direction]
         window:perform_action(act.SendKey({ key = key, mods = 'ALT|CTRL|SHIFT' }), pane)
      else
         -- Not in vim, use WezTerm pane navigation
         window:perform_action(act.ActivatePaneDirection(direction), pane)
      end
   end)
end

-- Conditionally resize in vim or WezTerm
local function smart_split_resize(direction)
   return wezterm.action_callback(function(window, pane)
      if is_vim(pane) then
         -- Send Alt+Ctrl+Shift+Arrow to vim
         local arrow = direction .. 'Arrow'
         window:perform_action(act.SendKey({ key = arrow, mods = 'ALT|CTRL|SHIFT' }), pane)
      else
         window:perform_action(act.AdjustPaneSize({ direction, 3 }), pane)
      end
   end)
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

   -- panes: smart navigation (integrates with neovim smart-splits)
   { key = 'UpArrow',     mods = mod.SUPER, action = smart_split_nav('Up') },
   { key = 'DownArrow',   mods = mod.SUPER, action = smart_split_nav('Down') },
   { key = 'LeftArrow',   mods = mod.SUPER, action = smart_split_nav('Left') },
   { key = 'RightArrow',  mods = mod.SUPER, action = smart_split_nav('Right') },

   -- panes: smart resize (integrates with neovim smart-splits)
   { key = 'UpArrow',     mods = mod.SUPER_REV, action = smart_split_resize('Up') },
   { key = 'DownArrow',   mods = mod.SUPER_REV, action = smart_split_resize('Down') },
   { key = 'LeftArrow',   mods = mod.SUPER_REV, action = smart_split_resize('Left') },
   { key = 'RightArrow',  mods = mod.SUPER_REV, action = smart_split_resize('Right') },

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
