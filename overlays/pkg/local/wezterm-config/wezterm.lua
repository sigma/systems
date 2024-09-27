local wezterm = require('wezterm')
local Config = require('config')

-- require('events.right-status').setup()
-- require('events.left-status').setup()
-- require('events.tab-title').setup()
-- require('events.new-tab-button').setup()
-- require('events.window-title').setup()
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local accent_colors = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]

tabline.setup {
   options = {
     icons_enabled = true,
     theme = "Overnight Slumber",
     color_overrides = {
       normal_mode = {
         a = {},
         b = { fg = "#A3C3AD" },
         c = {},
       },
       tab = {
         active = { bg = "#30463C" },
         inactive = {},
       }
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
     tabline_a = { },
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
     tabline_z = { "battery" },
   },
   extensions = {},
}

return Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
