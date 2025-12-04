{
  inputs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nebula;
  types = import ./types.nix { inherit lib; };
  helpers = import ./helpers.nix { inherit inputs lib cfg; };
  configurations = import ./configurations.nix {
    inherit
      inputs
      lib
      cfg
      helpers
      ;
    stateVersion = "25.11";
  };
  defaultFeatures = [
    "managed"
    "linux"
    "mac"
    "nixos"
    "interactive"
    "laptop"
  ];
  nixConfigTypes = types.submodule {
    options = {
      trusted-substituters = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      trusted-public-keys = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };
in
{
  options = {
    nebula = {
      users = mkOption {
        type = types.lazyAttrsOf types.user;
        default = { };
      };

      hosts = mkOption {
        type = types.lazyAttrsOf types.host;
        default = { };
      };

      features = mkOption {
        type = types.listOf types.str;
        default = defaultFeatures;
      };

      nixpkgsConfig = mkOption {
        type = types.attrs;
        default = { };
      };

      darwinModules = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      homeModules = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      linuxModules = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      nixosModules = mkOption {
        type = types.listOf types.raw;
        default = [ ];
      };

      userSelector = mkOption {
        type = types.functionTo types.user;
        default = machine: machine.user;
      };

      nixConfig = mkOption {
        type = nixConfigTypes;
        default = { };
      };
    };
  };

  config =
    let
      hosts = config.nebula.hosts;
      allMachines = builtins.mapAttrs (name: host: helpers.hostMachine host) hosts;
      machines = lib.filterAttrs (name: machine: machine.features.managed) allMachines;
    in
    {
      # make sure the predefined features are always included
      nebula.features = defaultFeatures;

      flake =
        let
          gen =
            feature:
            builtins.mapAttrs (name: machine: configurations.${feature} machine) (
              lib.filterAttrs (name: machine: machine.features.${feature}) machines
            );
        in
        {
          darwinConfigurations = gen "mac";
          homeConfigurations = gen "linux";
          nixosConfigurations = gen "nixos";
        };
    };
}
