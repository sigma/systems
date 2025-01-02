local gpu_adapters = require('utils.gpu_adapter')

local M = {}

M.apply_to_config = function(options, _opts)
   options.animation_fps = 60
   options.max_fps = 60
   options.front_end = 'WebGpu'
   options.webgpu_power_preference = 'HighPerformance'
   options.webgpu_preferred_adapter = gpu_adapters:pick_best()

   -- color scheme
   options.color_scheme = 'Subliminal'

   -- scrollbar
   options.enable_scroll_bar = true

   -- tab bar
   options.enable_tab_bar = true
   options.hide_tab_bar_if_only_one_tab = false
   options.use_fancy_tab_bar = false
   options.tab_max_width = 30
   options.show_tab_index_in_tab_bar = false
   options.switch_to_last_active_tab_when_closing_tab = true

   -- window
   options.window_padding = {
      left = 12,
      right = 10,
      top = 12,
      bottom = 7,
   }
   options.window_background_opacity = 0.9
   options.window_close_confirmation = 'NeverPrompt'
   options.window_decorations = "RESIZE"
   options.window_frame = {
      active_titlebar_bg = '#090909',
      -- font = fonts.font,
      -- font_size = fonts.font_size,
   }
   options.inactive_pane_hsb = {
      saturation = 0.9,
      brightness = 0.65,
   }

   options.macos_window_background_blur = 10
end

return M
