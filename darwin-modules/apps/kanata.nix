{
  config,
  lib,
  pkgs,
  user,
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
    inherit (cfg) devices;
    inherit (cfg.mods)
      swapAltCmd
      fnDndHack
      hyperFromLctl
      rOptHyper
      capsEscCtrl
      enterRctrl
      shiftParens
      bracketChords
      mediaKeys
      stockToggle
      ;
    inherit (cfg.timing) tapMs holdMs chordMs;
    inherit (cfg) pedal;
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
      rOptHyper = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Right Option becomes Hyper+Shift (Ctrl+Alt+Cmd+Shift).
          Takes precedence over `swapAltCmd` for that key.
        '';
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
      bracketChords = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Bottom-row chords for brackets/braces/angles:
          `zx`→`[`, `./`→`]`, `xc`→`{`, `,.`→`}`, `zc`→`<`, `,/`→`>`.
        '';
      };
      mediaKeys = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Top-row keys emit Apple media-key codes (brightness, mission
          control, spotlight, dictation, DND, media transport, mute,
          volume). Holding `fn` flips them back to plain F1-F12.
          Obsoletes `fnDndHack` — F6 emits the real DND code directly.
        '';
      };
      stockToggle = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Fn+Esc toggles a "stock" layer that bypasses all kanata
          remaps (no caps→Ctrl, no shift-parens, no chords, no
          alt↔cmd swap) — useful when handing the laptop to someone
          else. Requires `mediaKeys` (the toggle lives on the fkeys
          layer).
        '';
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
      chordMs = mkOption {
        type = types.int;
        default = 80;
        description = ''
          Maximum delay (ms) between successive chord-key presses
          for the chord to register. Tighter values reduce accidental
          triggers during fast rolling typing.
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
    #
    # The optional second block disables caps-lock on the Apple
    # internal keyboard at the macOS HID layer. Apple's LED is driven
    # by macOS when the *physical* key is pressed — independent of
    # what kanata then emits — so without this the LED toggles even
    # though the OS receives Esc/Ctrl. Stored in the per-host plist
    # under `0-0-0` (the internal-keyboard sentinel); HID code
    # 30064771129 = caps lock, 30064771072 = "No Action".
    system.activationScripts.postActivation.text = ''
      if launchctl print system/org.pqrs.service.daemon.karabiner_grabber >/dev/null 2>&1; then
        launchctl disable system/org.pqrs.service.daemon.karabiner_grabber || true
        launchctl bootout system/org.pqrs.service.daemon.karabiner_grabber || true
      fi
    ''
    + optionalString cfg.mods.capsEscCtrl ''
      uuid=$(/usr/sbin/ioreg -d2 -c IOPlatformExpertDevice | /usr/bin/awk -F'"' '/IOPlatformUUID/{print $4}')
      plist="/Users/${user.login}/Library/Preferences/ByHost/.GlobalPreferences.$uuid.plist"
      key='com.apple.keyboard.modifiermapping.0-0-0'
      if [ ! -f "$plist" ]; then
        sudo -u ${user.login} -- /usr/bin/plutil -create xml1 "$plist"
      fi
      # Idempotent: delete-then-add. PlistBuddy uses : as separator
      # so the dotted top-level key parses correctly (plutil would
      # mis-treat the dots as a nested path).
      sudo -u ${user.login} -- /usr/libexec/PlistBuddy -c "Delete :$key" "$plist" 2>/dev/null || true
      sudo -u ${user.login} -- /usr/libexec/PlistBuddy \
        -c "Add :$key array" \
        -c "Add :$key:0 dict" \
        -c "Add :$key:0:HIDKeyboardModifierMappingSrc integer 30064771129" \
        -c "Add :$key:0:HIDKeyboardModifierMappingDst integer 30064771072" \
        "$plist"
      sudo -u ${user.login} -- /usr/bin/killall cfprefsd 2>/dev/null || true
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
