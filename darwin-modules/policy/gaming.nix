{
  lib,
  machine,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf machine.features.gaming {
    user = {
      home.packages = with pkgs; [
        innoextract
      ];

      programs.dosbox = {
        enable = mkForce true;
      };
    };
  };
}
