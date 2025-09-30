{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.cursor;
in
{
  options.programs.cursor = {
    enable = mkEnableOption "cursor";
    package = mkPackageOption pkgs "cursor" {
      nullable = true;
    };
  };

  config = mkIf cfg.enable {
    programs.vscode.package = cfg.package;
  };
}
