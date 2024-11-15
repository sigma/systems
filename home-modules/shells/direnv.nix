{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.direnv;
in {
  config = mkIf cfg.enable {
    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
    };
  };
}
