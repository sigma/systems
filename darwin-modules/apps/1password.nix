{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.onepassword;
in
{
  options = {
    programs.onepassword = {
      enable = mkEnableOption "1Password";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "1password";
        args = {
          appdir = "/Applications";
        };
      }
      # The `op` CLI is a separate distribution from the desktop app; the app
      # bundle contains no `op` binary. This cask puts a real, functional `op`
      # in PATH and integrates with the desktop app for biometric unlock.
      "1password-cli"
    ];
  };
}
