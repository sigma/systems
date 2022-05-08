{ nixpkgs, nixpkgsConfig, darwin, darwinModules, home-manager, ... }:

let
  system = "aarch64-darwin";
  login = "yhodique";
in
darwin.lib.darwinSystem {
  inherit system;
  modules = nixpkgs.lib.attrValues darwinModules ++ [
    # Main `nix-darwin` config
    ../configuration.nix
    (import ../mac-user.nix login)
    # `home-manager` module
    home-manager.darwinModules.home-manager
    {
      nixpkgs = nixpkgsConfig;
      # `home-manager` config
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${login} = import ../home.nix;
    }
  ];
}
