{
  inputs,
  cfg,
  lib,
  stateVersion,
  helpers,
  ...
}: let
  systemRegistryModule = lib.optionalAttrs (cfg.systemRegistry != null) {
    nix.registry = cfg.systemRegistry;
  };

  userRegistryModule = lib.optionalAttrs (cfg.userRegistry != null) {
    nix.registry = cfg.userRegistry;
  };

  userFor = machine:
    helpers.expandUser (cfg.userSelector machine);

  homeManagerConfig = {
    user,
    machine,
  }: {
    nixpkgs = cfg.nixpkgsConfig;
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user.login} = inputs.nixpkgs.lib.mkMerge (
        cfg.homeModules
        ++ machine.homeModules
        ++ [
          userRegistryModule
        ]
      );
      extraSpecialArgs = {
        inherit user machine stateVersion;
      };
    };
  };
in {
  mac = machine: let
    user = userFor machine;
    specialArgs = {
      inherit user machine stateVersion;
    };
  in
    inputs.darwin.lib.darwinSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules =
        cfg.darwinModules
        ++ machine.darwinModules
        ++ [
          # `home-manager` module
          inputs.home-manager.darwinModules.home-manager
          (homeManagerConfig {inherit user machine;})
          systemRegistryModule
        ];
    };

  linux = machine: let
    user = userFor machine;
    specialArgs = {
      inherit user machine stateVersion;
    };
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${machine.system} // cfg.nixpkgsConfig;
      modules =
        cfg.homeModules
        ++ machine.homeModules
        ++ [
          (lib.optional (machine.homeRoot != null) {
            home = {
              username = user.login;
              homeDirectory = machine.homeRoot + user.login;
              inherit stateVersion;
            };
          })
        ]
        ++ lib.optionals cfg.homeMergeSystemRegistry [
          # this will end up in the user registry, as we don't have others
          systemRegistryModule
        ];
      extraSpecialArgs = specialArgs;
    };

  nixos = machine: let
    user = userFor machine;
    specialArgs = {
      inherit user machine stateVersion;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules =
        cfg.nixosModules
        ++ machine.nixosModules
        ++ [
          # 'home-manager' module
          inputs.home-manager.nixosModules.home-manager
          (homeManagerConfig {inherit user machine;})
          systemRegistryModule
        ];
    };
}
