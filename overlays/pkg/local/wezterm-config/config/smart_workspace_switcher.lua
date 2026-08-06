local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local smart_workspace_switcher = require('smart_workspace_switcher')

return function(config, _opts)
   config.default_workspace = "default"

   if not config.keys then
      config.keys = {}
   end

   local switch_action = smart_workspace_switcher.switch_workspace({ extra_args = " | rg 'src/github.com/[^/]*/[^/]*$'" })

   -- Wrap workspace switcher to only work in local domain
   local function local_only_workspace_switcher()
      return wezterm.action_callback(function(window, pane)
         if pane:get_domain_name() == "local" then
            window:perform_action(switch_action, pane)
         else
            -- Silently blocked - no action in SSH domain
            wezterm.log_info("Workspace switcher blocked: not in local domain")
         end
      end)
   end

   table.insert(config.keys, {
      key = "s",
      mods = "LEADER",
      action = local_only_workspace_switcher(),
   })

   table.insert(config.keys, {
      key = "S",
      mods = "LEADER",
      action = smart_workspace_switcher.switch_to_prev_workspace(),
   })
end
