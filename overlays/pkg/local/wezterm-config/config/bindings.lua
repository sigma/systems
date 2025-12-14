local wezterm = require('wezterm')
local platform = require('utils.platform')()

local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.STD = 'SUPER'
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|SHIFT'
   mod.SUPER_CTRL = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.STD = 'CTRL'
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
   mod.SUPER_CTRL = 'ALT|SHIFT'
end

-- Smart splits integration: detect if pane is running vim/neovim or emacs
local function get_editor_type(pane)
   local process_info = pane:get_foreground_process_info()
   local process_name = process_info and process_info.name or ''

   -- Check process name for editors (exact match on executable name)
   if process_name:find('^n?vim$') or process_name:find('^n?vim%.') then
      return 'vim'
   elseif process_name:find('^[Ee]macs') then
      return 'emacs'
   end

   -- Exclude known non-editors that might have "vim" in their output/title
   local title = pane:get_title() or ''
   if title:find('claude') or process_name:find('node') or process_name:find('claude') then
      return nil
   end

   -- Fallback: check pane title for editor patterns
   -- Use stricter patterns to avoid false positives
   if title:match('^n?vim%s') or title:match('%s+n?vim%s') or title:match('^n?vim$') then
      return 'vim'
   elseif title:match('^[Ee]macs') or title:match('%s+[Ee]macs') then
      return 'emacs'
   end

   return nil
end

-- Direction to hjkl for vim (used with SendKey)
local direction_to_key = {
   Left = 'h',
   Right = 'l',
   Up = 'k',
   Down = 'j',
}

local function smart_split_nav(direction)
   return wezterm.action_callback(function(window, pane)
      local editor = get_editor_type(pane)
      if editor == 'vim' then
         -- Send Alt+Ctrl+Shift+hjkl to Neovim (works with CSI u encoding)
         local key = direction_to_key[direction]
         window:perform_action(act.SendKey({ key = key, mods = 'ALT|CTRL|SHIFT' }), pane)
      elseif editor == 'emacs' then
         -- Send C-c <arrow> which is already mapped to windmove in Emacs
         window:perform_action(act.SendKey({ key = 'c', mods = 'CTRL' }), pane)
         window:perform_action(act.SendKey({ key = direction .. 'Arrow' }), pane)
      else
         -- Not in editor, use WezTerm pane navigation
         window:perform_action(act.ActivatePaneDirection(direction), pane)
      end
   end)
end

-- Conditionally resize in editor or WezTerm
local function smart_split_resize(direction)
   return wezterm.action_callback(function(window, pane)
      local editor = get_editor_type(pane)
      if editor then
         -- Send Alt+Ctrl+Shift+Arrow to editor
         local arrow = direction .. 'Arrow'
         window:perform_action(act.SendKey({ key = arrow, mods = 'ALT|CTRL|SHIFT' }), pane)
      else
         window:perform_action(act.AdjustPaneSize({ direction, 3 }), pane)
      end
   end)
end

-- Conditionally swap buffer/pane in editor or WezTerm
local function smart_split_swap(direction)
   return wezterm.action_callback(function(window, pane)
      local editor = get_editor_type(pane)
      if editor == 'vim' then
         -- Send Ctrl+Shift+Arrow to Neovim for buffer swap
         local arrow = direction .. 'Arrow'
         window:perform_action(act.SendKey({ key = arrow, mods = 'CTRL|SHIFT' }), pane)
      else
         -- Use directional pane swap (requires patched wezterm with PR #6821)
         local tab = window:active_tab()
         local target_pane = tab:get_pane_direction(direction)
         if target_pane then
            tab:swap_active_with_id(target_pane:pane_id(), true)
         end
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

   -- panes: smart swap (integrates with neovim smart-splits)
   { key = 'UpArrow',     mods = mod.SUPER_CTRL, action = smart_split_swap('Up') },
   { key = 'DownArrow',   mods = mod.SUPER_CTRL, action = smart_split_swap('Down') },
   { key = 'LeftArrow',   mods = mod.SUPER_CTRL, action = smart_split_swap('Left') },
   { key = 'RightArrow',  mods = mod.SUPER_CTRL, action = smart_split_swap('Right') },

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

   -- Handle swap requests from Neovim at edge via user var
   wezterm.on('user-var-changed', function(window, pane, name, value)
      if name == 'swap_pane_direction' and value ~= '' then
         local tab = window:active_tab()
         local target_pane = tab:get_pane_direction(value)
         if target_pane then
            tab:swap_active_with_id(target_pane:pane_id(), true)
         end
         -- Clear the var so it can be triggered again
         pane:set_user_var('swap_pane_direction', '')
      end
   end)
end

return M
