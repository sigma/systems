local wezterm = require('wezterm')

local M = {}

M.apply_to_config = function(options, _opts)
   options.font = wezterm.font{
      family = "FiraCode Nerd Font Mono",
      harfbuzz_features = {
        'cv01', 'cv02', 'cv04', 'ss01', 'ss02', 'ss05', 'cv18', 'ss03', 'cv16', 'cv29', 'cv31',
      },
   }
   options.font_size = 14

   --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   options.freetype_load_target = 'Normal'
   options.freetype_render_target = 'Normal'
end

return M
