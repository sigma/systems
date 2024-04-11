{
  user,
  config,
  lib,
  isMac,
  ...
}: let
  cfg = config.programs.blaze;
  platform =
    if isMac
    then "darwin"
    else "linux";
in {
  options.programs.blaze = {
    enable = lib.mkEnableOption "blaze";
  };

  config = lib.mkIf cfg.enable {
    home.file =
      {
        ".blazerc".text = ''
          try-import %workspace%/experimental/users/${user.login}/config/${platform}.blazerc
          import %workspace%/experimental/users/${user.login}/config/blazerc
        '';
      }
      // lib.optionalAttrs isMac {
        ".exoblazerc".text = ''
          startup --noexoblaze
        '';
      };
  };
}
