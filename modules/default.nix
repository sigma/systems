{inputs, ...}: {
  imports = [
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
    inputs.nix-index-database.hmModules.nix-index
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  nebula.nixosModules = [
    ../nixos-modules
    inputs.catppuccin.nixosModules.catppuccin
  ];

  nebula.darwinModules = [
    ../darwin-modules
    inputs.flox.darwinModules.flox
  ];

  nebula.nixpkgsConfig = import ../pkg-config.nix {inherit inputs;};

  nebula.nixConfig = {
    trusted-substituters = [
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };
}
