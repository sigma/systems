{
  inputs,
  lib,
  config,
  ...
}: let
  fplib = inputs.flake-parts.lib;
  inherit (lib) mkOption types literalExpression;
  inherit (fplib) mkSubmoduleOptions;
in {
  flake = let
    inherit (config.defs) machines hosts;
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
      };
    };

    config = {
      # My `nix-darwin` configs
      darwinConfigurations = {
        yhodique-macbookpro = machines.mac hosts.yhodique-macbookpro;
        yhodique-macmini = machines.mac hosts.yhodique-macmini;
      };

      # My home-manager only configs
      homeConfigurations = {
        # glinux is an anonymous profile, useful for dynamically created
        # instances that I can't be bothered to register here.
        glinux = machines.glinux {};
        shirka = machines.glinux hosts.shirka;
      };
    };
  };
}
