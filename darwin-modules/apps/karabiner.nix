{
  config,
  lib,
  user,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;
  cfgTxt = builtins.toJSON (import ./karabiner/config.nix {inherit lib cfg;});
in {
  options.programs.karabiner = {
    enable = mkEnableOption "Karabiner";

    internalKeyboardID = mkOption {
      type = types.raw;
      description = "The internal keyboard ID for a laptop";
      default = {
        vendor_id = 1452;
        product_id = 835;
        is_keyboard = true;
      };
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "karabiner-elements"
    ];
    home-manager.users.${user.login}.home.file.".config/karabiner/karabiner.json".text = cfgTxt;
  };
}
