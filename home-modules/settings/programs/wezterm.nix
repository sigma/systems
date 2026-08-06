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
    if config.programs.antigravity.enable then
      config.programs.antigravity.package
    else if config.programs.cursor.enable then
      config.programs.cursor.package
    else
      config.programs.vscode.package;

  editorBin =
    if config.programs.antigravity.enable then
      "antigravity"
    else if config.programs.cursor.enable then
      "cursor"
    else
      "code";

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
         local domain = pane:get_domain_name()

          if domain == "local" then
            -- Local domain: open in Editor
            window:perform_action(
              wezterm.action.SpawnCommandInNewTab {
                args = { '${editor}/bin/${editorBin}', url.file_path },
                domain = "DefaultDomain",
              },
              pane
            )
          else
           -- SSH domain: open in neovim on the remote
           window:perform_action(
             wezterm.action.SpawnCommandInNewTab {
               args = { 'nvim', url.file_path },
             },
             pane
           )
         end

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
             -- Force local execution even when in SSH domain
             domain = "DefaultDomain",
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
