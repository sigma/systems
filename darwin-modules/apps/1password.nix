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
    ];
  };
}
