local wezterm = require('wezterm')

-- Inspired by https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614

local nf = wezterm.nerdfonts

local GLYPH_SEMI_CIRCLE_LEFT = nf.ple_left_half_circle_thick --[[ '' ]]
local GLYPH_SEMI_CIRCLE_RIGHT = nf.ple_right_half_circle_thick --[[ '' ]]
local GLYPH_CIRCLE = nf.fa_circle --[[ '' ]]
local GLYPH_ADMIN = nf.md_shield_half_full --[[ '󰞀' ]]
local GLYPH_UBUNTU = nf.cod_terminal_linux

local M = {}

local __cells__ = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

-- stylua: ignore
local colors = {
   default   = { bg = '#45475a', fg = '#1c1b19' },
   is_active = { bg = '#7FB4CA', fg = '#11111b' },
   hover     = { bg = '#587d8c', fg = '#1c1b19' },
}

local _set_process_name = function(s)
   local a = string.gsub(s, '(.*[/\\])(.*)', '%2')
   return a:gsub('%.exe$', '')
end

local _set_title = function(_tab, process_name, base_title, max_width, inset)
   local title
   inset = inset or 6

   if process_name:len() > 0 then
      title = process_name .. ' :: ' .. base_title
   else
      title = base_title
   end

   if title:len() > (max_width - inset) then
      local diff = title:len() - max_width + inset
      title = wezterm.truncate_right(title, title:len() - diff)
   end

   return title
end

local _process_icons = {
   -- containers
   ['docker'] = wezterm.nerdfonts.linux_docker,
   ['docker-compose'] = wezterm.nerdfonts.linux_docker,
   ['kubectl'] = wezterm.nerdfonts.linux_docker,
   ['kuberlr'] = wezterm.nerdfonts.linux_docker,
   ['lazydocker'] = wezterm.nerdfonts.linux_docker,
   ['stern'] = wezterm.nerdfonts.linux_docker,

   -- network
   ['curl'] = wezterm.nerdfonts.mdi_flattr,
   ['ssh'] = wezterm.nerdfonts.fa_exchange,
   ['ssh-add'] = wezterm.nerdfonts.fa_exchange,
   ['wget'] = wezterm.nerdfonts.mdi_arrow_down_box,

   -- editors
   ['emacs'] = wezterm.nerdfonts.custom_emacs,
   ['nvim'] = wezterm.nerdfonts.custom_vim,
   ['vim'] = wezterm.nerdfonts.dev_vim,
  
   -- languages
   ['cargo'] = wezterm.nerdfonts.dev_rust,
   ['go'] = wezterm.nerdfonts.seti_go2,
   ['lua'] = wezterm.nerdfonts.seti_lua,
   ['make'] = wezterm.nerdfonts.seti_makefile,
   ['node'] = wezterm.nerdfonts.mdi_hexagon,
   ['python3'] = wezterm.nerdfonts.dev_python,
   ['Python'] = wezterm.nerdfonts.dev_python,
   ['ruby'] = wezterm.nerdfonts.cod_ruby,

   -- git
   ['gh'] = wezterm.nerdfonts.dev_github_badge,
   ['git'] = wezterm.nerdfonts.dev_git,

   -- shells
   ['bash'] = wezterm.nerdfonts.seti_shell,
   ['zsh'] = wezterm.nerdfonts.seti_shell,

   -- system
   ['htop'] = wezterm.nerdfonts.mdi_chart_donut_variant,
   ['sudo'] = wezterm.nerdfonts.fa_hashtag,
}

local function _get_current_working_dir(tab)
   local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = '' }
   local HOME_DIR = os.getenv('HOME')
 
   return current_dir.file_path == HOME_DIR and '~'
     or string.gsub(current_dir.file_path, '(.*[/\\])(.*)', '%2')
end

local function _get_process(tab)
   if not tab.active_pane or tab.active_pane.foreground_process_name == '' then
     return nil
   end
 
   local process_name = string.gsub(tab.active_pane.foreground_process_name, '(.*[/\\])(.*)', '%2')
   if string.find(process_name, 'kubectl') then
     process_name = 'kubectl'
   end
 
   return _process_icons[process_name] or string.format('[%s]', process_name)
end

---@param fg string
---@param bg string
---@param attribute table
---@param text string
local _push = function(bg, fg, attribute, text)
   table.insert(__cells__, { Background = { Color = bg } })
   table.insert(__cells__, { Foreground = { Color = fg } })
   table.insert(__cells__, { Attribute = attribute })
   table.insert(__cells__, { Text = text })
end

M.setup = function()
   wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, hover, max_width)
      __cells__ = {}

      local bg
      local fg

      local inset = 6
      local title
      local base_title = tab.tab_title
      -- prioritize tab title over process name
      if base_title and #base_title > 0 then
         title = _set_title(tab, '', base_title, max_width, inset)
      else
         local cwd = _get_current_working_dir(tab)
         local process_name = _get_process(tab)
         title = _set_title(tab, process_name, cwd, max_width, inset)
      end

      if tab.is_active then
         bg = colors.is_active.bg
         fg = colors.is_active.fg
      elseif hover then
         bg = colors.hover.bg
         fg = colors.hover.fg
      else
         bg = colors.default.bg
         fg = colors.default.fg
      end

      local has_unseen_output = false
      for _, pane in ipairs(tab.panes) do
         if pane.has_unseen_output then
            has_unseen_output = true
            break
         end
      end

      -- Left semi-circle
      _push('rgba(0, 0, 0, 0.4)', bg, { Intensity = 'Bold' }, GLYPH_SEMI_CIRCLE_LEFT)

      -- Title
      _push(bg, fg, { Intensity = 'Bold' }, ' ' .. title)

      -- Unseen output alert
      if has_unseen_output then
         _push(bg, '#28719c', { Intensity = 'Bold' }, ' ' .. GLYPH_CIRCLE)
      else
         _push(bg, '#28719c', { Intensity = 'Bold' }, '  ') -- I don't want tab width to change based on unseen output
      end

      -- Right padding
      _push(bg, fg, { Intensity = 'Bold' }, ' ')

      -- Right semi-circle
      _push('rgba(0, 0, 0, 0.4)', bg, { Intensity = 'Bold' }, GLYPH_SEMI_CIRCLE_RIGHT)

      return __cells__
   end)
end

return M
