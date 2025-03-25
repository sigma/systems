{
  config,
  lib,
  machine,
  user,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;
  cfgTxt = builtins.toJSON (import ./karabiner/config.nix {inherit lib cfg machine user;});

  kbdType = types.submodule {
    options = {
      vendorId = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "The vendor ID of the keyboard";
      };
      productId = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "The product ID of the keyboard";
      };
    };
  };
in {
  options.programs.karabiner = {
    enable = mkEnableOption "Karabiner";

    internalKeyboard = mkOption {
      type = kbdType;
      description = "The internal keyboard for a laptop";
      default = {
        vendorId = 1452;
        productId = 835;
      };
    };

    pedal = mkOption {
      type = types.nullOr kbdType;
      description = "The pedal keyboard";
      default = null;
    };

    pedalKeys = mkOption {
      type = types.attrsOf (types.either types.str (types.attrsOf types.str));
      description = "The keys the pedal natively emits";
      default = {
        "left" = {pointing_button = "button1";};
        "right" = {pointing_button = "button2";};
        "middle" = {pointing_button = "button3";};
      };
    };

    pedalComboDevice = mkOption {
      type = types.bool;
      description = "Whether the pedal is a combo device";
      default = false;
    };

    ignoreKeyboards = mkOption {
      type = types.listOf kbdType;
      description = "The keyboards to ignore";
      default = [];
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "karabiner-elements"
    ];
    home-manager.users.${user.login}.home.file.".config/karabiner/karabiner.json".text = cfgTxt;

    # Hack for karabiner: register F16 as the "do not disturb" shortcut.
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys."175" = {
      enabled = true;
      value = {
        parameters = [65535 106 8388608];
        type = "standard";
      };
    };
  };
}
