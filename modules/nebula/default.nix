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
  # Builder type for nixConfig.builders
  builderEntryType = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      system = mkOption { type = types.str; };
      alias = mkOption { type = types.nullOr types.str; default = null; };
      maxJobs = mkOption { type = types.int; default = 4; };
      speedFactor = mkOption { type = types.int; default = 1; };
      supportedFeatures = mkOption { type = types.listOf types.str; default = [ ]; };
      publicHostKey = mkOption { type = types.nullOr types.str; default = null; };
      sshUser = mkOption { type = types.str; default = "nixbuilder"; };
      sshPublicKey = mkOption { type = types.nullOr types.str; default = null; };
      storePublicKey = mkOption { type = types.nullOr types.str; default = null; };
    };
  };

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
      builders = mkOption {
        type = types.attrsOf builderEntryType;
        default = { };
        description = "All available builders keyed by hostname";
      };
    };
  };
in
{
  imports = [ ./secrets.nix ];

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
        allMachines = builtins.mapAttrs (name: host: helpers.hostMachine name host) hosts;
        machines = lib.filterAttrs (name: machine: machine.features.managed) allMachines;

        # Compute builder mesh from all hosts with builder.enable
        builderHosts = lib.filterAttrs
          (name: m: m.builder != null && m.builder.enable or false)
          machines;

        # Transform to builder entries for nixConfig
        builderEntries = lib.mapAttrs (name: m: {
          inherit (m) name system alias;
          inherit (m.builder)
            maxJobs
            speedFactor
            supportedFeatures
            publicHostKey
            sshUser
            sshPublicKey
            storePublicKey
            ;
        }) builderHosts;

        # Collect store signing public keys from all builders
        builderStoreKeys = lib.filter (k: k != null) (
          lib.mapAttrsToList (name: m: m.builder.storePublicKey or null) builderHosts
        );
      in
      {
        # make sure the predefined features are always included
        nebula.features = defaultFeatures;

        # Populate builders in nixConfig
        nebula.nixConfig.builders = builderEntries;

        # Add builder store keys to trusted-public-keys
        nebula.nixConfig.trusted-public-keys = lib.mkAfter builderStoreKeys;

        flake =
        let
          # Generate configurations for machines with a specific feature
          gen =
            feature: builder:
            builtins.mapAttrs (name: machine: builder machine) (
              lib.filterAttrs (name: machine: machine.features.${feature}) machines
            );

          # Generate home configurations with $machine-$user naming
          # Also provides $machine alias when there's a single user
          genHome =
            feature: builder:
            let
              filteredMachines = lib.filterAttrs (name: machine: machine.features.${feature}) machines;
              # Generate $machine-$user entries
              perUserConfigs = lib.concatMapAttrs (name: machine:
                let
                  user = helpers.expandUser (cfg.userSelector machine);
                in
                {
                  "${name}-${user.login}" = builder machine;
                }
              ) filteredMachines;
              # Generate $machine aliases (pointing to same config)
              machineAliases = builtins.mapAttrs (name: machine: builder machine) filteredMachines;
            in
            perUserConfigs // machineAliases;
        in
        {
          darwinConfigurations = gen "mac" configurations.mac;
          homeConfigurations =
            (genHome "linux" configurations.linux)
            // (genHome "mac" configurations.macHome)
            // (genHome "nixos" configurations.nixosHome);
          nixosConfigurations = gen "nixos" configurations.nixos;
        };
    };
}
