local wezterm = require('wezterm')
local platform = require('utils.platform')

return {
   font = wezterm.font{
      family = "FiraCode Nerd Font Mono",
      harfbuzz_features = {
        'cv01', 'cv02', 'cv04', 'ss01', 'ss05', 'cv18', 'ss03', 'cv16', 'cv31',
      },
   },
   font_size = 14,

   --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
