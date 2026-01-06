local wezterm = require('wezterm')
local platform = require('utils.platform')()

local act = wezterm.action

-- SSH domain selector: opens a fuzzy menu to connect to configured SSH domains
wezterm.on('trigger-ssh-domain-selector', function(window, pane)
   local ssh_domains = wezterm.GLOBAL.ssh_domains or {}
   local choices = {}

   for _, domain in ipairs(ssh_domains) do
      table.insert(choices, {
         id = domain.name,
         label = domain.name,
      })
   end

   if #choices == 0 then
      wezterm.log_warn('No SSH domains configured')
      return
   end

   window:perform_action(
      act.InputSelector {
         title = 'Connect to SSH Domain',
         fuzzy = true,
         choices = choices,
         action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
            if id then
               inner_window:perform_action(
                  act.SpawnCommandInNewWindow { domain = { DomainName = id } },
                  inner_pane
               )
            end
         end),
      },
      pane
   )
end)

return function(config, _opts)
   -- Note: ssh_domains are set by Nix from machine.remotes
   -- We don't initialize them here to avoid overwriting

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   config.unix_domains = config.unix_domains or {}

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   config.wsl_domains = config.wsl_domains or {}

   -- Store ssh_domains in GLOBAL so the event handler can access them
   -- (they get populated by Nix after this module runs)
   wezterm.on('window-config-reloaded', function()
      wezterm.GLOBAL.ssh_domains = config.ssh_domains or {}
   end)

   -- Keybinding for SSH domain selector
   config.keys = config.keys or {}
   local mod = platform.is_mac and 'CMD|SHIFT' or 'ALT|SHIFT'
   table.insert(config.keys, {
      key = 's',
      mods = mod,
      action = act.EmitEvent 'trigger-ssh-domain-selector',
   })
end
