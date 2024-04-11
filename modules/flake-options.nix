{
  inputs,
  lib,
  ...
}: let
  fplib = inputs.flake-parts.lib;
  inherit
    (lib)
    mkOption
    types
    literalExpression
    ;
  inherit
    (fplib)
    mkSubmoduleOptions
    ;
in {
  options = {
    flake = mkSubmoduleOptions {
      darwinConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Instantiated Darwin configurations.
        '';
        example =
          literalExpression ''
          '';
      };
      homeConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Instantiated home-manager configurations.
        '';
        example =
          literalExpression ''
          '';
      };
      defs = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Definitions.
        '';
      };
    };
  };
}
