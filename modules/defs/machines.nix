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
in {
  mac = machine: let
    user =
      if machine.isWork
      then users.corpUser
      else users.personalUser;
    specialArgs = {
      inherit user machine stateVersion;
      isMac = true;
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
        {
          nixpkgs = nixpkgsConfig;
          # `home-manager` config
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user.login} = inputs.nixpkgs.lib.mkMerge hmModules;
          home-manager.extraSpecialArgs = specialArgs;
        }
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
      isMac = false;
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
}
