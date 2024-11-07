local wezterm = require('wezterm')

local accent_colors = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]

local mantle = accent_colors.background
local surface0 = mantle
local blue = accent_colors.ansi[5]
local text = accent_colors.foreground
local yellow = accent_colors.ansi[4]
local green = accent_colors.ansi[3]
local pink = accent_colors.ansi[6]
local red = accent_colors.ansi[1]

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
      { Foreground = { Color = accent_colors.ansi[3] } },
      "index",
      "ResetAttributes",
      { Foreground = { Color = accent_colors.foreground } },
      { "process", icons_only = true },
      { Attribute = { Intensity = "Bold" } },
      { "cwd", max_length = 20, padding = { left = 0, right = 1 } },
    },
    tab_inactive = {
      { Foreground = { Color = accent_colors.ansi[6] } },
      "index",
      "ResetAttributes",
      { "process", icons_only = true },
      { Attribute = { Intensity = "Bold" } },
      { "cwd", max_length = 20, padding = { left = 0, right = 1 } },
    },
    tabline_x = { },
    tabline_y = {
     { "datetime", style = "%a %d %b %Y %H:%M", hour_to_icon = "" },
    },
    tabline_z = { "workspace" },
  },
  extensions = {},
}

require('tabline.config').set(tabline_opts)

wezterm.on('update-status', function(window)
  require('tabline.component').set_status(window)
end)

wezterm.on('format-tab-title', function(tab, _, _, _, hover, _)
  return require('tabline.tabs').set_title(tab, hover)
end)

return {}