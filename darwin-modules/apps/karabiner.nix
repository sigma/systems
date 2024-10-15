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
  };
}
