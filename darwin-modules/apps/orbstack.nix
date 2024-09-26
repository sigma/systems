{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.orbstack;
in {
  options = {
    programs.orbstack = {
      enable = mkEnableOption "orbstack";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "orbstack";
        args = {appdir = "/Applications";};
      }
    ];
  };
}
