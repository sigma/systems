local wezterm = require('wezterm')
local M = {}

M.apply_to_config = function(options, _opts)
   options.automatically_reload_config = true
   options.exit_behavior = 'CloseOnCleanExit'
   options.exit_behavior_messaging = 'Verbose'
   options.status_update_interval = 1000

   options.scrollback_lines = 5000

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

   -- This is the main event handler for opening links
   wezterm.on('open-uri', function(window, pane, uri) 
      -- Check for a file URI (e.g., file:///path/to/your/file)
      if uri:find('^file:') then
        -- WezTerm's URL parser helps extract the clean file path
        local url = wezterm.url.parse(uri)
      
        -- Use SpawnCommandInNewTab to open the file with VS Code
        -- This keeps the output from the command contained in a new tab
        window:perform_action(
          wezterm.action.SpawnCommandInNewTab {
            -- The command to run. 'code' should be in your system's PATH.
            args = { '/usr/local/bin/cursor', url.file_path },
          },
          pane
        )
     
        -- Return false to prevent wezterm's default link handling
        return false
      end
 
      -- Check for standard web URLs
      if uri:find('^https://') or uri:find('^http://') then
        -- IMPORTANT: Replace this path with the actual path to your script
        local open_url_script = '/etc/profiles/per-user/yann/bin/open-url'
      
        window:perform_action(
          wezterm.action.SpawnCommandInNewTab {
            -- Pass the clicked URL as an argument to your script
            args = { open_url_script, uri },
          },
          pane
        )
     
        return false
      end
      -- If the URI is not a file or web URL, let the default handler try it
      -- (This will return `nil`, allowing the chain to continue)
   end)
end

return M
