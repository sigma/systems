{
  lib,
  pkgs,
  config,
  ...
}:
let
  weztermConfig = pkgs.local.wezterm-config;
in
{
  enable = true;
  extraConfig = ''
    local wezterm = require('wezterm')
    package.path = package.path .. ";${weztermConfig}/?.lua;${weztermConfig}/?/init.lua"

    local config = dofile("${weztermConfig}/wezterm.lua")
      ${lib.optionalString config.catppuccin.wezterm.enable ":apply(dofile(catppuccin_plugin))"}

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
             args = { '${config.programs.cursor.package}/bin/cursor', url.file_path },
           },
           pane
         )
      
         -- Return false to prevent wezterm's default link handling
         return false
       end

       -- Check for standard web URLs
       if uri:find('^https://') or uri:find('^http://') then
         -- IMPORTANT: Replace this path with the actual path to your script
         local open_url_script = '${config.programs.open-url.package}/bin/open-url'
       
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

    return config.options
  '';
}
