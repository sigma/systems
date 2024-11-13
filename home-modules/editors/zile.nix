{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.zile;
in {
  options.programs.zile = {
    enable = mkEnableOption "Zile";
    package = mkOption {
      type = types.package;
      default = pkgs.zile;
    };
    configFile = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    home.file.".zile" = mkIf (cfg.configFile != "") {
      text = "${cfg.configFile}";
    };

    home.sessionVariables = let
      editor = "${cfg.package}/bin/zile";
    in {
      EDITOR = editor;
      VISUAL = editor;
    };
  };
}
