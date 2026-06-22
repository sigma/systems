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

  # Wezterm's font weight expects a string from a known set, not a number.
  weightToWezterm =
    w:
    {
      "100" = "Thin";
      "200" = "ExtraLight";
      "300" = "Light";
      "400" = "Regular";
      "500" = "Medium";
      "600" = "DemiBold";
      "700" = "Bold";
      "800" = "ExtraBold";
      "900" = "Black";
    }
    .${toString w} or "Regular";

  termProfile = config.programs.fontProfiles.terminal;

  luaQuoted = s: "\"${s}\"";
  luaList = items: "{ ${lib.concatStringsSep ", " items} }";

  primaryFontLua =
    let
      features = lib.optional (termProfile.features != [ ]) (
        "harfbuzz_features = ${luaList (map luaQuoted termProfile.features)}"
      );
      weight = lib.optional (termProfile.weight != null) (
        "weight = ${luaQuoted (weightToWezterm termProfile.weight)}"
      );
      attrs = [ "family = ${luaQuoted termProfile.family.family}" ] ++ features ++ weight;
    in
    "{ ${lib.concatStringsSep ", " attrs} }";

  fbName = f: if lib.isString f then f else f.family;
  fallbackFontLua = map (f: luaQuoted (fbName f)) termProfile.fallbacks;

  fontWithFallbackLua = luaList ([ primaryFontLua ] ++ fallbackFontLua);
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
        c.font = wezterm.font_with_fallback(${fontWithFallbackLua})
        c.font_size = ${toString termProfile.size}
      end)
      :apply(function(c)
        c.ssh_domains = {
          ${sshDomainsLua}
        }
      end)

    -- This is the main event handler for opening links
    wezterm.on('open-uri', function(window, pane, uri)
       -- file URI: send `nvim <path>` to the current pane so the
       -- shell launches nvim in place (rather than spawning a new
       -- tab). Works the same locally and over SSH — the active
       -- shell's PATH resolves nvim.
       if uri:find('^file:') then
         local url = wezterm.url.parse(uri)
         window:perform_action(
           wezterm.action.SendString('nvim ' .. wezterm.shell_join_args({ url.file_path }) .. '\r'),
           pane
         )
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
