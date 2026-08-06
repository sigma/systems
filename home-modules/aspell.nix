{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.aspell;
in
{
  options.programs.aspell = {
    enable = mkEnableOption "aspell";

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "Resulting customized aspell package.";
    };

    extraDicts = mkOption {
      default =
        ds: with ds; [
          en
          en-computers
          en-science
        ];
      defaultText = "ds: with ds; [ en en-computers en-science ]";
      description = "Extra dictionaries to install.";
      type = types.functionTo (types.listOf types.package);
    };
  };

  config = mkIf cfg.enable {
    programs.aspell.package = pkgs.aspellWithDicts cfg.extraDicts;
    home.packages = [
      cfg.package
    ];
  };
}
