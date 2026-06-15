{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.kanata;

  # Homebrew install path. We use homebrew rather than nixpkgs because
  # macOS TCC (Input Monitoring / Accessibility) is tied to the binary
  # path, and the nix-store path rotates on every kanata upgrade —
  # silently re-breaking the daemon each time.
  kanataBin = "/opt/homebrew/bin/kanata";

  kanataConfig = (import ../../modules/kanata/config.nix { inherit lib; }).mkConfig {
    platform = "macos";
    devices = cfg.devices;
    inherit (cfg.mods)
      swapAltCmd
      fnDndHack
      hyperFromLctl
      capsEscCtrl
      enterRctrl
      shiftParens
      ;
    inherit (cfg.timing) tapMs holdMs;
    pedal = cfg.pedal;
  };

  # The config lives in the nix store so its path is a content hash.
  # Referencing this path from the plist makes plist regen → daemon
  # reload happen automatically on config change during activation.
  kanataConfigFile = pkgs.writeText "kanata-config.kbd" kanataConfig;

  pedalSubmodule = types.submodule {
    options = {
      left = mkOption {
        type = types.str;
        default = "f18";
        description = "Output key emitted by the left pedal.";
      };
      right = mkOption {
        type = types.str;
        default = "ret";
        description = "Output key emitted by the right pedal.";
      };
      middle = mkOption {
        type = types.str;
        default = "lmet";
        description = "Output key emitted by the middle pedal.";
      };
    };
  };
in
{
  options.programs.kanata = {
    enable = mkEnableOption "Kanata keyboard remapper";

    devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Device product-name substrings for kanata to intercept
        (`macos-dev-names-include`). Anything not listed passes through
        untouched.
      '';
    };

    mods = {
      swapAltCmd = mkOption {
        type = types.bool;
        default = false;
        description = "PC-style modifier swap: lopt↔lmet, ropt↔rmet.";
      };
      fnDndHack = mkOption {
        type = types.bool;
        default = false;
        description = "Remap F6 → F16 (paired with a Do-Not-Disturb hotkey on F16).";
      };
      hyperFromLctl = mkOption {
        type = types.bool;
        default = false;
        description = "Left Control becomes Hyper (Ctrl+Alt+Cmd).";
      };
      capsEscCtrl = mkOption {
        type = types.bool;
        default = false;
        description = "Caps Lock: tap=Esc, hold=Ctrl.";
      };
      enterRctrl = mkOption {
        type = types.bool;
        default = false;
        description = "Return: tap=Return, hold=Right Control.";
      };
      shiftParens = mkOption {
        type = types.bool;
        default = false;
        description = "Shift tap: left=`(`, right=`)`; hold behaves as Shift.";
      };
    };

    timing = {
      tapMs = mkOption {
        type = types.int;
        default = 200;
        description = ''
          Maximum press duration (ms) that still counts as a tap for
          tap-hold aliases. Pressed-and-released within this window
          fires the tap action.
        '';
      };
      holdMs = mkOption {
        type = types.int;
        default = 200;
        description = ''
          Time-based hold fallback (ms). Holding past this window
          without pressing any other key still commits to the hold
          action. (With tap-hold-press, pressing another key during
          the window also commits to hold regardless of this value.)
        '';
      };
    };

    pedal = mkOption {
      type = types.nullOr pedalSubmodule;
      default = null;
      description = ''
        Pedal output mapping. Assumes the pedal hardware has been
        programmed to emit F20/F21/F22 from left/right/middle (kanata
        on macOS cannot intercept HID mouse-button events from pedals).

        Left defaults to F18; pair with System Settings → Keyboard →
        Dictation Shortcut = F18 to trigger dictation.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Karabiner-Elements ships the DriverKit Virtual HID device that
    # kanata writes to on macOS. We keep the cask installed for the
    # driver only — its own grabber is disabled below.
    homebrew.casks = [ "karabiner-elements" ];
    homebrew.brews = [ "kanata" ];

    # /etc copy is for human inspection (`bat /etc/kanata/config.kbd`);
    # the daemon reads directly from the nix-store path below.
    environment.etc."kanata/config.kbd".source = kanataConfigFile;

    # Kanata configs are S-expressions; Lisp highlighting is the closest fit.
    user.programs.bat.config.map-syntax = [ "*.kbd:Lisp" ];

    launchd.daemons.kanata = {
      serviceConfig = {
        Label = "com.kanata";
        ProgramArguments = [
          kanataBin
          "--cfg"
          "${kanataConfigFile}"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
      };
    };

    # Karabiner-Elements' grabber would compete with kanata for HID
    # access. Best-effort disable on each activation; safe to fail if
    # the daemon isn't installed yet.
    system.activationScripts.postActivation.text = ''
      if launchctl print system/org.pqrs.service.daemon.karabiner_grabber >/dev/null 2>&1; then
        launchctl disable system/org.pqrs.service.daemon.karabiner_grabber || true
        launchctl bootout system/org.pqrs.service.daemon.karabiner_grabber || true
      fi
    '';

    # Same DND-on-F16 system shortcut the karabiner module wires up.
    # Needed whenever fnDndHack is on so the OS reacts to the F16
    # kanata emits when F6 is pressed.
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys."175" =
      mkIf cfg.mods.fnDndHack {
        enabled = true;
        value = {
          parameters = [
            65535
            106
            8388608
          ];
          type = "standard";
        };
      };
  };
}
