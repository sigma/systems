local platform = require('utils.platform')

local M = {}

M.apply_to_config = function(options, _opts)
   options.automatically_reload_config = true

   -- On Linux, default to the gcr-ssh-agent socket so that remote mux
   -- clients that don't carry their own SSH_AUTH_SOCK still get a working agent.
   local runtime_dir = os.getenv('XDG_RUNTIME_DIR')
   if platform().is_linux and runtime_dir then
      options.default_ssh_auth_sock = runtime_dir .. '/gcr/ssh'
   end
   options.exit_behavior = 'CloseOnCleanExit'
   options.exit_behavior_messaging = 'Verbose'
   options.status_update_interval = 1000

   -- Enable CSI u key encoding for proper modifier key handling in Neovim
   options.enable_csi_u_key_encoding = true

   options.scrollback_lines = 5000

   -- Quick select patterns (ctrl+shift+space to activate)
   options.quick_select_patterns = {
      -- jj change IDs: 8-32 character sequences from k-z alphabet
      '[k-z]{8,32}',
   }

   options.hyperlink_rules = {
      -- Matches: a URL in parens: (URL)
      {
         regex = '\\((\\w+://\\S+)\\)',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in brackets: [URL]
      {
         regex = '\\[(\\w+://\\S+)\\]',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in curly braces: {URL}
      {
         regex = '\\{(\\w+://\\S+)\\}',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in angle brackets: <URL>
      {
         regex = '<(\\w+://\\S+)>',
         format = '$1',
         highlight = 1,
      },
      -- Then handle URLs not wrapped in brackets
      {
         regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
         format = '$0',
      },
      -- implicit mailto link
      {
         regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
         format = 'mailto:$0',
      },
   }
end

return M
