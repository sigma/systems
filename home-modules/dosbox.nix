{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.dosbox;

  # Get all files from the MT-32 ROMs package
  mt32piFiles = builtins.readDir "${cfg.mt32Roms}";

  configPath =
    if pkgs.stdenv.isDarwin then
      lib.const "Library/Preferences/DOSBox/mt32-roms"
    else
      lib.const ".config/dosbox/mt32-roms";
in
{
  options.programs.dosbox = {
    enable = mkEnableOption "dosbox";

    mt32Roms = mkOption {
      type = types.package;
      default = pkgs.local.mt32-roms;
      description = "Roland MT-32 ROM files for DOSBox";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.dosbox-staging
    ];

    # Create individual symlinks for each ROM file
    home.file = lib.mapAttrs' (
      name: type:
      lib.nameValuePair "${configPath}/${name}" {
        source = "${cfg.mt32Roms}/${name}";
      }
    ) mt32piFiles;
  };
}
