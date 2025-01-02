local smart_workspace_switcher = require('smart_workspace_switcher')

return function(config, _opts)
   config.default_workspace = "default"

   if not config.keys then
      config.keys = {}
   end

   table.insert(config.keys, {
      key = "s",
      mods = "LEADER",
      action = smart_workspace_switcher.switch_workspace({ extra_args = " | rg 'src/github.com/[^/]*/[^/]*$'" }),
   })

   table.insert(config.keys, {
      key = "S",
      mods = "LEADER",
      action = smart_workspace_switcher.switch_to_prev_workspace(),
   })
end
