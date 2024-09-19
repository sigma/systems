{
  config,
  lib,
  machine,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;
  cfgTxt = builtins.toJSON (import ./karabiner/config.nix {inherit lib;});
in
  lib.optionalAttrs machine.isMac {
    options.programs.karabiner = {
      enable = mkEnableOption "Karabiner";
    };

    config = mkIf cfg.enable {
      home.file.".config/karabiner/karabiner.json".text = cfgTxt;
    };
  }
