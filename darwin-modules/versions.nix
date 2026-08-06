{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  vrsPkg = pkgs.runCommandLocal "version" { } ''
    mkdir -p $out
    /usr/bin/sw_vers --productVersion > $out/version
  '';
  vrs = builtins.readFile "${vrsPkg}/version";
  cfg = config.versions.darwin;
in
{
  options = {
    versions.darwin = {
      reference = mkOption {
        type = types.str;
        description = "The reference version to compare to";
        default = vrs;
      };

      lib = mkOption {
        type = types.raw;
        description = "Library functions for version comparison";
        default =
          let
            compareTo = builtins.compareVersions cfg.reference;
          in
          {
            versionAtLeast = version: compareTo version >= 0;
            versionAtMost = version: compareTo version <= 0;
            versionEqual = version: compareTo version == 0;
          };
      };
    };
  };
}
