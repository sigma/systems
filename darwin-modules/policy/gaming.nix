{
  lib,
  pkgs,
  user,
  machine,
  ...
}:
with lib;
{
  config = mkIf machine.features.gaming {
    programs.joyride = {
      enable = true;
      user = user.login;
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
