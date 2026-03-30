{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib;
let
  cfg = config.programs.gpad2mouse;
  appName = "gpad2mouse";
  appDir = "/Users/${user.login}/Applications/${appName}.app";
  storePkg = pkgs.local.gpad2mouse;
in
{
  options.programs.gpad2mouse = {
    enable = mkEnableOption "gpad2mouse gamepad-to-mouse daemon";

    excludeApps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Bundle IDs where gpad2mouse is disabled (gamepad passthrough)";
    };

    cursorSpeed = mkOption {
      type = types.int;
      default = 1500;
      description = "Cursor speed in pixels/sec at full stick deflection";
    };

    dpadSpeed = mkOption {
      type = types.int;
      default = 150;
      description = "D-pad cursor speed in pixels/sec (precise movement)";
    };

    scrollSpeed = mkOption {
      type = types.int;
      default = 8;
      description = "Scroll speed multiplier";
    };

    naturalScroll = mkOption {
      type = types.bool;
      default = false;
      description = "Use natural scrolling direction";
    };
  };

  config = mkIf cfg.enable {
    # Copy the app bundle to ~/Applications and sign with system codesign.
    # This gives a stable path for TCC (Accessibility) permissions.
    system.activationScripts.postActivation.text = ''
      echo >&2 "installing ${appName}.app..."
      mkdir -p "${appDir}/Contents/MacOS"
      cp "${storePkg}/Applications/${appName}.app/Contents/MacOS/${appName}" "${appDir}/Contents/MacOS/"
      cp "${storePkg}/Applications/${appName}.app/Contents/Info.plist" "${appDir}/Contents/"
      /usr/bin/codesign --force --sign - --identifier dev.${appName} "${appDir}"
    '';

    launchd.user.agents.gpad2mouse = {
      serviceConfig = {
        ProgramArguments =
          [
            "${appDir}/Contents/MacOS/gpad2mouse"
          ]
          ++ optionals (cfg.excludeApps != [ ]) [
            "--exclude"
            (concatStringsSep "," cfg.excludeApps)
          ]
          ++ [
            "--cursor-speed"
            (toString cfg.cursorSpeed)
            "--dpad-speed"
            (toString cfg.dpadSpeed)
            "--scroll-speed"
            (toString cfg.scrollSpeed)
          ]
          ++ optionals cfg.naturalScroll [
            "--natural-scroll"
          ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/gpad2mouse.log";
        StandardErrorPath = "/tmp/gpad2mouse.log";
      };
    };
  };
}
