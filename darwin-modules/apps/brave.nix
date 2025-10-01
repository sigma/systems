{
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.programs.brave;
  homeDir = config.users.users.${user.login}.home;
in
{
  options.programs.brave = {
    enable = mkEnableOption "brave";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "brave-browser";
        args = {
          appdir = "/Applications";
        };
      }
    ];

    home-manager.users.${user.login}.programs = {
      open-url = {
        enable = true;
        browser = "/Applications/Brave Browser.app";
        localStatePath = "${homeDir}/Library/Application Support/BraveSoftware/Brave-Browser/Local State";
      };

      yt-dlp = {
        settings = {
          cookies-from-browser = "brave";
        };
      };
    };
  };
}
