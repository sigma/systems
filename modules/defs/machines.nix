{ 
  inputs,
  stateVersion,
  users
}:

let
  # Configuration for `nixpkgs`
  nixpkgsConfig = rec {
    config = {allowUnfree = true;};
    overlays = import ../../overlays { inherit inputs config; };
  };
  hmModules = [
    ../../home-modules
    inputs.nix-doom-emacs.hmModule
  ];
in
{
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
      modules =
        [
          # Main `nix-darwin` config
          ../../configuration.nix
          ../../darwin-modules/gmac.nix
          ../../darwin-modules/mac-user.nix
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
    user = users.corpUser;
    specialArgs = {
      inherit user stateVersion;
      machine =
        {
          isInteractive = false;
          system = "x86_64-linux";
        }
        // machine
        // {isWork = true;};
      isMac = false;
    };
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = builtins.getAttr "x86_64-linux" inputs.nixpkgs.outputs.legacyPackages // nixpkgsConfig;
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
