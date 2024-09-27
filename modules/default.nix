{inputs, ...}: {
  imports = [
    # shell support
    ./shell.nix

    # configurations generation with nebula
    ./nebula
    ./users.nix
    ./hosts.nix
  ];

  nebula.homeModules = [
    ../home-modules
    inputs.chemacs2nix.homeModule
    inputs.nix-index-database.hmModules.nix-index
  ];

  nebula.nixosModules = [
    ../nixos-modules
  ];

  nebula.darwinModules = [
    ../darwin-modules
  ];

  nebula.nixpkgsConfig = import ../pkg-config.nix {inherit inputs;};
}
