{
  config,
  lib,
  machine,
  ...
}:
with lib; let
  cfg = config.programs.aerospace;
in
  lib.optionalAttrs machine.isMac {
    options.programs.aerospace = {
      enable = mkEnableOption "Aerospace";

      autostart = mkEnableOption "Autostart Aerospace at login";
    };

    config = mkIf cfg.enable {
      home.file.".aerospace.toml".text = import ./aerospace/config.nix cfg;
    };
  }
