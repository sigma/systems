{
  inputs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.nebula;
  types = import ./types.nix {inherit lib;};
  helpers = import ./helpers.nix {inherit lib cfg;};
  configurations = import ./configurations.nix {
    inherit inputs lib cfg helpers;
    stateVersion = "24.05";
  };
  defaultFeatures = ["managed" "linux" "mac" "nixos" "interactive" "laptop"];
in {
  options = {
    nebula = {
      users = mkOption {
        type = types.lazyAttrsOf types.user;
        default = {};
      };

      hosts = mkOption {
        type = types.lazyAttrsOf types.host;
        default = {};
      };

      features = mkOption {
        type = types.listOf types.str;
        default = defaultFeatures;
      };

      nixpkgsConfig = mkOption {
        type = types.attrs;
        default = {};
      };

      darwinModules = mkOption {
        type = types.listOf types.raw;
        default = [];
      };

      homeModules = mkOption {
        type = types.listOf types.raw;
        default = [];
      };

      nixosModules = mkOption {
        type = types.listOf types.raw;
        default = [];
      };

      userSelector = mkOption {
        type = types.functionTo types.user;
        default = machine: machine.user;
      };

      userRegistry = mkOption {
        type = types.nullOr types.registry;
        default = null;
      };

      systemRegistry = mkOption {
        type = types.nullOr types.registry;
        default = null;
      };

      homeMergeSystemRegistry = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = let
    hosts = config.nebula.hosts;
    allMachines = builtins.mapAttrs (name: host: helpers.hostMachine host) hosts;
    machines = lib.filterAttrs (name: machine: machine.features.managed) allMachines;
  in {
    # make sure the predefined features are always included
    nebula.features = defaultFeatures;

    flake = let
      gen = feature: builtins.mapAttrs (name: machine: configurations.${feature} machine) (lib.filterAttrs (name: machine: machine.features.${feature}) machines);
    in {
      darwinConfigurations = gen "mac";
      homeConfigurations = gen "linux";
      nixosConfigurations = gen "nixos";
    };
  };
}
