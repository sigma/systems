{
  inputs,
  stateVersion,
  users,
}: let
  # Configuration for `nixpkgs`
  nixpkgsConfig = import ../../pkg-config.nix {inherit inputs;};
  hmModules = [
    ../../home-modules
    inputs.chemacs2nix.homeModule
    inputs.nix-index-database.hmModules.nix-index
  ];

  # Common home-manager configuration
  homeManagerConfig = {
    user,
    machine,
  }: {
    nixpkgs = nixpkgsConfig;
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${user.login} = inputs.nixpkgs.lib.mkMerge hmModules;
      extraSpecialArgs = {inherit user machine stateVersion;};
    };
  };
in {
  mac = machine: let
    user =
      if machine.isWork
      then users.corpUser
      else users.personalUser;
    specialArgs = {
      inherit user machine stateVersion;
    };
  in
    inputs.darwin.lib.darwinSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules = [
        # Main `nix-darwin` config
        ../../darwin-modules
        # `home-manager` module
        inputs.home-manager.darwinModules.home-manager
        (homeManagerConfig {inherit user machine;})
      ];
    };

  glinux = machine: let
    system = "x86_64-linux";
    user = users.corpUser;
    specialArgs = {
      inherit user stateVersion;
      machine =
        {
          inherit system;
          isInteractive = false;
        }
        // machine
        // {isWork = true;};
    };
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system} // nixpkgsConfig;
      modules =
        hmModules
        ++ [
          {
            home = {
              username = user.login;
              homeDirectory = "/usr/local/google/home/${user.login}";
              inherit stateVersion;
            };
          }
        ];
      extraSpecialArgs = specialArgs;
    };

  nixos = machine: let
    user = users.personalUser;
    specialArgs = {
      inherit user machine stateVersion;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (machine) system;
      inherit specialArgs;
      modules = [
        ../../nixos-modules
        # 'home-manager' module
        inputs.home-manager.nixosModules.home-manager
        (homeManagerConfig {inherit user machine;})
      ];
    };
}
