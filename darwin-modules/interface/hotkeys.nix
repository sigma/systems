{
  config,
  lib,
  ...
}: let
  cfg = config.interface.hotkeys;
in
  with lib; {
    options.interface.hotkeys = {
      disable = mkOption {
        type = types.listOf types.int;
        default = [];
      };
    };

    config =
      mkIf (cfg.disable != []) {
        system.activationScripts.extraUserActivation.text = let
          disableHotKeyCommands = map (key: "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${toString key} '
<dict>
  <key>enabled</key><false/>
  <key>value</key>
  <dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>65535</integer>
      <integer>0</integer>
    </array>
  </dict>
</dict>'") cfg.disable;
        in ''
          echo >&2 "configuring hotkeys..."
          ${concatStringsSep "\n" disableHotKeyCommands}
          # credit: https://zameermanji.com/blog/2021/6/8/applying-com-apple-symbolichotkeys-changes-instantaneously/
          /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';
      };
  }
