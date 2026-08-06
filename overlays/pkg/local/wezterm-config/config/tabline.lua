local wezterm = require('wezterm')
local tabline_config = require('tabline.config')

local accent_colors = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]

local mantle = accent_colors.background
local surface0 = mantle
local text = accent_colors.foreground

-- Catppuccin Mocha explicit colors
local peach = "#fab387"
local red = "#f38ba8"
local yellow = "#f9e2af"
local green = "#a6e3a1"
local pink = "#f5c2e7"
local blue = "#89b4fa"

local tabline_opts = {
  options = {
    icons_enabled = true,
    theme = "Catppuccin Mocha",
    color_overrides = {
      font_resize_mode = {
        a = { fg = mantle, bg = yellow },
        b = { fg = yellow, bg = surface0 },
        c = { fg = text, bg = mantle },
      },
      pane_resize_mode = {
        a = { fg = mantle, bg = green },
        b = { fg = green, bg = surface0 },
        c = { fg = text, bg = mantle },
      },
    },
    section_separators = {
      left = wezterm.nerdfonts.ple_right_half_circle_thick,
      right = wezterm.nerdfonts.ple_left_half_circle_thick,
    },
    component_separators = {
      left = wezterm.nerdfonts.ple_right_half_circle_thin,
      right = wezterm.nerdfonts.ple_left_half_circle_thin,
    },
    tab_separators = {
      left = wezterm.nerdfonts.ple_right_half_circle_thick,
      right = wezterm.nerdfonts.ple_left_half_circle_thick,
    },
  },
  sections = {
    tabline_a = {
      { 
        "mode",
        cond = function(window)
          return window:active_key_table() ~= nil
        end,
      },
    },
    tabline_b = { },
    tabline_c = { },
    tab_active = {
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { Color = green } },
      "index",
      { Foreground = { Color = text } },
      { "process", icons_only = true },
      { Attribute = { Intensity = "Bold" } },
      { "tab", max_length = 20, padding = { left = 0, right = 1 } },
      { 'zoomed', padding = 0 },
      "ResetAttributes",
    },
    tab_inactive = {
      { Foreground = { Color = pink } },
      "index",
      { "process", icons_only = true },
      { Attribute = { Intensity = "Bold" } },
      { "tab", max_length = 20, padding = { left = 0, right = 1 } },
      "ResetAttributes",
    },
    tabline_x = { },
    tabline_y = {
     { "datetime", style = "%a %d %b %Y %H:%M", hour_to_icon = "" },
    },
    tabline_z = { "workspace" },
  },
  extensions = {},
}

local M = {}

-- Check if a tab is in an SSH domain
local function is_ssh_domain(tab)
  local pane = tab.active_pane
  if pane and pane.domain_name and pane.domain_name ~= "local" then
    return true, pane.domain_name
  end
  return false, nil
end

M.apply_to_config = function(_options, _opts)
  tabline_config.set(tabline_opts)

  wezterm.on('update-status', function(window)
    require('tabline.component').set_status(window)
  end)

  wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local is_ssh, domain_name = is_ssh_domain(tab)

    if is_ssh then
      -- Custom rendering for SSH domain tabs with orange/red accent
      local title = tab.tab_title
      if #title == 0 then
        title = tab.active_pane.title
      end
      -- Truncate if needed
      if #title > 20 then
        title = title:sub(1, 17) .. "..."
      end

      local bg_color = tab.is_active and peach or surface0
      local fg_color = tab.is_active and mantle or peach
      local edge_fg = tab.is_active and peach or surface0

      -- Rounded separators (same as tabline plugin)
      local left_sep = wezterm.nerdfonts.ple_left_half_circle_thick
      local right_sep = wezterm.nerdfonts.ple_right_half_circle_thick

      local index = tab.tab_index + 1  -- 1-indexed for display

      return {
        -- Left rounded edge
        { Background = { Color = mantle } },
        { Foreground = { Color = edge_fg } },
        { Text = left_sep },
        -- Tab content
        { Background = { Color = bg_color } },
        { Foreground = { Color = fg_color } },
        { Attribute = { Intensity = "Bold" } },
        { Text = " " .. index .. " " },
        { Text = wezterm.nerdfonts.md_server_network .. " " },
        { Attribute = { Intensity = "Normal" } },
        { Text = domain_name .. ": " .. title .. " " },
        -- Right rounded edge
        { Background = { Color = mantle } },
        { Foreground = { Color = edge_fg } },
        { Text = right_sep },
      }
    else
      -- Use default tabline rendering for local tabs
      return require('tabline.tabs').set_title(tab, hover)
    end
  end)
end

return M
