{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.antigravity;
in
{
  options.programs.antigravity = {
    enable = mkEnableOption "antigravity";
    package = mkPackageOption pkgs "antigravity" {
      nullable = true;
    };
  };

  config = mkIf cfg.enable {
    programs.vscode.package = cfg.package;
  };
}
