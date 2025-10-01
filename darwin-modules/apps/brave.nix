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
  appDir = "/Applications";
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
          appdir = appDir;
        };
      }
    ];

    home-manager.users.${user.login}.programs = {
      open-url = {
        enable = true;
        # per cask appdir above
        browser = "${appDir}/Brave Browser.app";
        # standard location for the user local state
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
