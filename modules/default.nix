{ inputs, ... }:
{
  imports = [
    # flake packages
    ./flake-packages.nix

    # shell support
    ./shell.nix

    # configurations generation with nebula
    ./nebula
    ./users.nix
    ./hosts.nix
    ./registry.nix
  ];

  nebula.homeModules = [
    ../home-modules
    inputs.chemacs2nix.homeModule
    inputs.nix-index-database.homeModules.nix-index
    inputs.catppuccin.homeModules.catppuccin
  ];

  nebula.nixosModules = [
    ../nixos-modules
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nebula.darwinModules = [
    ../darwin-modules
  ];

  nebula.nixpkgsConfig = import ../pkg-config.nix { inherit inputs; };
}
