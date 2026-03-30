{
  lib,
  machine,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf machine.features.gaming {
    programs.gpad2mouse = {
      enable = true;
      excludeApps = [
        "com.trash80.m8c"
        "com.valvesoftware.steam"
      ];
    };

    user = {
      home.packages = with pkgs; [
        innoextract
      ];

      programs.dosbox = {
        enable = mkForce true;
      };
    };

    homebrew.casks = [
      "balenaetcher"
    ];
  };
}
