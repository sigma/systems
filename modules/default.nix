{ inputs, ... }:
{
  imports = [
    # flake packages
    ./flake-packages.nix

    # shell support
    ./shell.nix

    # secrets management
    ./secrets.nix

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
    inputs.noctalia.homeModules.default
    inputs.nvf.homeManagerModules.default
  ];

  nebula.nixosModules = [
    ../common-system-modules
    ../nixos-modules
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nebula.darwinModules = [
    ../common-system-modules
    ../darwin-modules
  ];

  nebula.nixpkgsConfig = import ../pkg-config.nix { inherit inputs; };
}
