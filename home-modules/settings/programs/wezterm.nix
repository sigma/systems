{
  lib,
  pkgs,
  config,
  machine,
  ...
}:
let
  # Interactive = has a GUI (Mac or NixOS with desktop)
  interactive = machine.features.mac || machine.features.interactive;

  weztermConfig = pkgs.local.wezterm-config;
  editor =
    if config.programs.cursor.enable then
      config.programs.cursor.package
    else
      config.programs.vscode.package;

  # Generate SSH domains from machine remotes
  # For NixOS hosts, use -mux suffix for remote_address to avoid RequestTTY force
  # which breaks WezTerm's multiplexing protocol
  remoteToDomain =
    remote:
    let
      domainName = if remote.alias != null then remote.alias else remote.name;
      isNixOS = builtins.elem "nixos" (remote.features or [ ]);
      remoteAddress = if isNixOS then "${domainName}-mux" else domainName;
    in
    ''
      {
              name = "${domainName}",
              remote_address = "${remoteAddress}",
              multiplexing = "WezTerm",
            }'';

  sshDomainsLua =
    if machine.remotes == [ ] then
      ""
    else
      lib.concatStringsSep ",\n    " (map remoteToDomain machine.remotes);
in
{
  enable = true;

  # Use headless variant on non-interactive machines (just the mux server)
  package = if interactive then pkgs.wezterm else pkgs.wezterm-headless;

  # Only apply full config on interactive machines
  extraConfig = lib.optionalString interactive ''
    local wezterm = require('wezterm')
    package.path = package.path .. ";${weztermConfig}/?.lua;${weztermConfig}/?/init.lua"

    local config = dofile("${weztermConfig}/wezterm.lua")
      ${lib.optionalString config.catppuccin.wezterm.enable ":apply(dofile(catppuccin_plugin))"}
      :apply(function(c)
        c.ssh_domains = {
          ${sshDomainsLua}
        }
      end)

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
             args = { '${editor}/bin/cursor', url.file_path },
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
