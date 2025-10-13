{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.just;
in
{
  options.programs.just = {
    enabled = mkEnableOption "just";
  };

  config = mkIf cfg.enabled {
    home.packages = [
      pkgs.just
    ];
  };
}
