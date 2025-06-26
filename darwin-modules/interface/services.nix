{
  config,
  lib,
  ...
}: let
  cfg = config.interface.services;
in
  with lib; {
    options.interface.services = {
      disable = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };

    config =
      mkIf (cfg.disable != []) {
        system.activationScripts.services.text = let
          disableServicesCommands = map (key: "defaults write pbs NSServicesStatus -dict-add '${key}' '
<dict>
  <key>enabled_context_menu</key><false/>
  <key>enabled_services_menu</key><false/>
  <key>presentation_modes</key>
  <dict>
    <key>ContextMenu</key><false/>
    <key>ServicesMenu</key><false/>
  </dict>
</dict>'") cfg.disable;
        in ''
          echo >&2 "disabling Terminal services..."
          ${concatStringsSep "\n" (map (cmd: "sudo -u ${user.login} -- " + cmd) disableServicesCommands)}
        '';
      };
  }
