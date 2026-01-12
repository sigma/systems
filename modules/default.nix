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
    inputs.vscode-server.nixosModules.default
  ];

  nebula.darwinModules = [
    ../common-system-modules
    ../darwin-modules
  ];

  nebula.nixpkgsConfig = import ../pkg-config.nix { inherit inputs; };

  nebula.nixConfig = {
    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://sigma.cachix.org"
      "https://fbx-vm.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "sigma.cachix.org-1:zUmpJONcvA/FnIH8pDADMNAyXT+HuOdnPmcWkq7z/R0="
      "fbx-vm.cachix.org-1:CvmtxfPovXiSGaHkUsKXKE+xRV1bMd0ppp7Uz1sKNFc="
    ];
  };
}
