{ nixpkgs, nixpkgsConfig, darwin, darwinModules, home-manager, user, ... }:

let
  system = "aarch64-darwin";
in
darwin.lib.darwinSystem {
  inherit system;
  modules = nixpkgs.lib.attrValues darwinModules ++ [
    # Main `nix-darwin` config
    ../configuration.nix
    (import ../mac-user.nix user.login)
    # `home-manager` module
    home-manager.darwinModules.home-manager
    {
      nixpkgs = nixpkgsConfig;
      # `home-manager` config
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user.login} = import ../home.nix;
      home-manager.extraSpecialArgs = {
        inherit user;
      };
    }
  ];
}
