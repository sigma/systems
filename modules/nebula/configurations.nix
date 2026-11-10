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
  secretsCfg = cfg.secrets;

  homeManagerConfig =
    {
      user,
      machine,
    }:
    {
      # nixpkgs config is set via nixpkgsConfigModule - don't duplicate here
      # as lists (like overlays) get concatenated, causing duplicate patches
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user.login} = inputs.nixpkgs-stable.lib.mkMerge (cfg.homeModules ++ machine.homeModules);
        extraSpecialArgs = {
          inherit user machine stateVersion;
          inherit (cfg) nixConfig;
        };
      };
    };

  nixModule = {
    nix.settings.substituters = cfg.nixConfig.trusted-substituters;
    nix.settings.trusted-public-keys = cfg.nixConfig.trusted-public-keys;
  };

  # Module to apply nixpkgs config (overlays, allowUnfree, etc.)
  # Defined once to avoid duplication across darwin/nixos/home configs
  nixpkgsConfigModule = {
    nixpkgs = cfg.nixpkgsConfig;
  };

  # Check if sops should be active (enabled AND has a secrets file)
  sopsActive = secretsCfg.enable && secretsCfg.defaultSopsFile != null;

  # Common sops configuration builder
  sopsConfigFor =
    {
      isHome ? false,
      user ? null,
      isDarwin ? false,
    }:
    {
      inherit (secretsCfg) defaultSopsFile;
      age = {
        sshKeyPaths =
          let
            homeDir = if isDarwin then "/Users/${user.login}" else "/home/${user.login}";
            expandPath =
              p:
              if lib.hasPrefix "/" p then
                p
              else if lib.hasPrefix "~" p then
                builtins.replaceStrings [ "~" ] [ homeDir ] p
              else
                "${homeDir}/${p}";
          in
          map expandPath secretsCfg.sshKeyPaths;
      }
      // lib.optionalAttrs (secretsCfg.ageKeyFile != null) {
        keyFile = secretsCfg.ageKeyFile;
      };
      secrets = lib.mapAttrs (
        name: secret:
        let
          # Expand "@user" to the actual user login
          expandOwner = o: if o == "@user" then user.login else o;
        in
        {
          inherit (secret) mode;
        }
        // lib.optionalAttrs (secret.sopsFile != null) { inherit (secret) sopsFile; }
        // lib.optionalAttrs (!isHome && secret.owner != null) { owner = expandOwner secret.owner; }
        // lib.optionalAttrs (!isHome && secret.group != null) { inherit (secret) group; }
      ) secretsCfg.secrets;
    };

  # sops-nix modules - only include when secrets are enabled AND secrets file exists
  sopsDarwinModules =
    user:
    lib.optionals sopsActive [
      inputs.sops-nix.darwinModules.sops
      {
        sops = sopsConfigFor {
          isDarwin = true;
          inherit user;
        };
      }
    ];

  sopsNixosModules =
    user:
    lib.optionals sopsActive [
      inputs.sops-nix.nixosModules.sops
      { sops = sopsConfigFor { inherit user; }; }
    ];

  sopsHomeModules =
    user:
    lib.optionals sopsActive [
      inputs.sops-nix.homeManagerModules.sops
      {
        sops = sopsConfigFor {
          isHome = true;
          inherit user;
        };
      }
    ];

  # Standalone home-manager config for a darwin or NixOS machine: the full
  # system's own home-manager user, passed through. Extracting it from the
  # system builder itself (not a copy of its module list) keeps a standalone
  # switch identical to a full one, and avoids re-evaluating modules, which
  # causes option rename/removal conflicts.
  homeOf =
    system: machine:
    let
      hmUserConfig = system.config.home-manager.users.${(userFor machine).login};
    in
    # Wrap to match homeManagerConfiguration's output structure
    {
      inherit (hmUserConfig.home) activationPackage;
      config = hmUserConfig;
      inherit (hmUserConfig) news newsDisplay newsEntries;
    };
in
rec {
  mac =
    machine:
    let
      user = userFor machine;
      specialArgs = {
        inherit user machine stateVersion;
        inherit (machine) system;
        inherit (cfg) nixConfig;
      };
    in
    inputs.darwin.lib.darwinSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules =
        cfg.darwinModules
        ++ machine.darwinModules
        ++ [
          # nixpkgs configuration (overlays, allowUnfree)
          nixpkgsConfigModule
          # `home-manager` module
          inputs.home-manager.darwinModules.home-manager
          (homeManagerConfig { inherit user machine; })
          nixModule
        ]
        ++ (sopsDarwinModules user);
    };

  macHome = machine: homeOf (mac machine) machine;

  linux =
    machine:
    let
      user = userFor machine;
      specialArgs = {
        inherit user machine stateVersion;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs-stable.legacyPackages.${machine.system} // cfg.nixpkgsConfig;
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
        ]
        ++ (sopsHomeModules user);
      extraSpecialArgs = specialArgs;
    };

  nixos =
    machine:
    let
      user = userFor machine;
      specialArgs = {
        inherit user machine stateVersion;
        inherit (cfg) nixConfig;
      };
      sharedModules =
        cfg.nixosModules
        ++ machine.nixosModules
        ++ [
          # nixpkgs configuration (overlays, allowUnfree)
          nixpkgsConfigModule
          # 'home-manager' module
          inputs.home-manager.nixosModules.home-manager
          (homeManagerConfig { inherit user machine; })
          nixModule
        ]
        ++ (sopsNixosModules user);
    in
    if machine.devbox != null then
      inputs.devbox.lib.mkDevbox {
        nixpkgs = inputs.nixpkgs-stable;
        inherit (machine) system;
        inherit specialArgs;
        inherit (machine.devbox) hypervisor;
        vm = {
          nested = machine.devbox.nested or false;
          memoryMB = machine.devbox.memoryMB or null;
          diskGB = machine.devbox.diskGB or 50;
        };
        modules = sharedModules ++ [
          # Bridge: the new flake's auto-installer reads the bootstrap user
          # from config.devbox.user.login, while this repo carries the login
          # in the `user` specialArg. Tie them together so SSH key paths in
          # the installer match the post-rebuild user that configuration.nix
          # creates. Substituters declared in nebula.nixConfig flow into
          # devbox.nix.* so the auto-installer ISO, the bootstrap config it
          # writes, and the host-side `nix build` of the installer all
          # benefit from the same caches the rest of the fleet uses.
          {
            devbox.user.login = user.login;
            devbox.nix.substituters = cfg.nixConfig.trusted-substituters;
            devbox.nix.trustedPublicKeys = cfg.nixConfig.trusted-public-keys;
          }
        ];
      }
    else
      inputs.nixpkgs-stable.lib.nixosSystem {
        inherit (machine) system;
        inherit specialArgs;
        modules = sharedModules;
      };

  nixosHome = machine: homeOf (nixos machine) machine;
}
