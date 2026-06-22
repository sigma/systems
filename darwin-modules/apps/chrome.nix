{
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.programs.chrome;
  homeDir = config.users.users.${user.login}.home;
  appDir = "/Applications";
in
{
  options.programs.chrome = {
    enable = mkEnableOption "Google Chrome";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "google-chrome";
        args = {
          appdir = appDir;
        };
      }
    ];

    user.programs = {
      open-url = {
        enable = true;
        # per cask appdir above
        browser = "${appDir}/Google Chrome.app";
        # standard location for the user local state
        localStatePath = "${homeDir}/Library/Application Support/Google/Chrome/Local State";
      };

      yt-dlp = {
        settings = {
          cookies-from-browser = "chrome";
        };
      };
    };
  };
}
