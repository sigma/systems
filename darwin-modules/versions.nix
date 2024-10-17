{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  vrsPkg = pkgs.runCommandLocal "version" {} ''
    mkdir -p $out
    /usr/bin/sw_vers --productVersion > $out/version
  '';
  vrs = builtins.readFile "${vrsPkg}/version";
  cfg = config.versions.darwin;
in {
  options = {
    versions.darwin = {
      reference = mkOption {
        type = types.str;
        description = "The reference version to compare to";
        default = vrs;
      };

      compareTo = mkOption {
        type = types.functionTo types.int;
        description = "Function to compare the current version to the provided version";
        default = builtins.compareVersions cfg.reference;
      };
    };
  };
}
