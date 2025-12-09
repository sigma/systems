{
  inputs,
  cfg,
  lib,
  stateVersion,
  helpers,
  ...
}:
let
  userFor = machine: helpers.expandUser (cfg.userSelector machine);

  homeManagerConfig =
    {
      user,
      machine,
    }:
    {
      nixpkgs = cfg.nixpkgsConfig;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user.login} = inputs.nixpkgs.lib.mkMerge (cfg.homeModules ++ machine.homeModules);
        extraSpecialArgs = {
          inherit user machine stateVersion;
        };
      };
    };

  nixModule = {
    nix.settings.substituters = cfg.nixConfig.trusted-substituters;
    nix.settings.trusted-public-keys = cfg.nixConfig.trusted-public-keys;
  };

  # Build standalone home-manager config for darwin machines.
  #
  # Strategy: Evaluate the full darwin system and directly expose its
  # home-manager user configuration. This avoids re-evaluating modules
  # which causes option rename/removal conflicts.
  #
  # The darwin system's home-manager.users.<login> already has all the
  # attributes that homeManagerConfiguration would produce (activationPackage,
  # config, etc.), so we just pass it through.
  macHome =
    machine:
    let
      user = userFor machine;
      # Build the full darwin system to get the complete home-manager config
      darwinSystem = inputs.darwin.lib.darwinSystem {
        inherit (machine) system;
        specialArgs = {
          inherit user machine stateVersion;
          inherit (machine) system;
        };
        modules =
          cfg.darwinModules
          ++ machine.darwinModules
          ++ [
            inputs.home-manager.darwinModules.home-manager
            (homeManagerConfig { inherit user machine; })
            nixModule
          ];
      };
      # The home-manager user config from darwin
      hmUserConfig = darwinSystem.config.home-manager.users.${user.login};
    in
    # Wrap to match homeManagerConfiguration's output structure
    {
      activationPackage = hmUserConfig.home.activationPackage;
      config = hmUserConfig;
      # Include other commonly used attributes
      inherit (hmUserConfig) news newsDisplay newsEntries;
    };

  # Build standalone home-manager config for NixOS machines.
  # Same strategy as macHome - directly use the NixOS system's home-manager config.
  nixosHome =
    machine:
    let
      user = userFor machine;
      # Build the full NixOS system to get the complete home-manager config
      nixosSystem = inputs.nixpkgs.lib.nixosSystem {
        inherit (machine) system;
        specialArgs = {
          inherit user machine stateVersion;
        };
        modules =
          cfg.nixosModules
          ++ machine.nixosModules
          ++ [
            inputs.home-manager.nixosModules.home-manager
            (homeManagerConfig { inherit user machine; })
            nixModule
          ];
      };
      hmUserConfig = nixosSystem.config.home-manager.users.${user.login};
    in
    {
      activationPackage = hmUserConfig.home.activationPackage;
      config = hmUserConfig;
      inherit (hmUserConfig) news newsDisplay newsEntries;
    };
in
{
  mac =
    machine:
    let
      user = userFor machine;
      specialArgs = {
        inherit user machine stateVersion;
        inherit (machine) system;
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
          (homeManagerConfig { inherit user machine; })
          nixModule
        ];
    };

  inherit macHome;

  linux =
    machine:
    let
      user = userFor machine;
      specialArgs = {
        inherit user machine stateVersion;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${machine.system} // cfg.nixpkgsConfig;
      modules =
        cfg.homeModules
        ++ cfg.linuxModules
        ++ machine.homeModules
        ++ [
          (lib.optional (machine.homeRoot != null) {
            home = {
              username = user.login;
              homeDirectory = machine.homeRoot + user.login;
              inherit stateVersion;
            };
          })
        ];
      extraSpecialArgs = specialArgs;
    };

  nixos =
    machine:
    let
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
          (homeManagerConfig { inherit user machine; })
          nixModule
        ];
    };

  inherit nixosHome;
}
