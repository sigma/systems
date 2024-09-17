{
  config,
  lib,
  machine,
  ...
}:
with lib; let
  cfg = config.programs.karabiner;
in
  lib.optionalAttrs machine.isMac {
    options.programs.karabiner = {
      enable = mkEnableOption "Karabiner";
    };

    config = mkIf cfg.enable {
      home.file.".config/karabiner/karabiner.json".text = builtins.toJSON (import ./karabiner/config.nix cfg);
    };
  }
