{
  description = "Yann's systems";

  inputs = {
    # Systems
    systems.url = "path:./flake.systems.nix";
    systems.flake = false;

    # Package sets
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    nixos-stable.url = github:NixOS/nixpkgs/nixos-22.11;
    darwin-stable.url = github:NixOS/nixpkgs/nixpkgs-22.11-darwin;
    nixpkgs-master.url = github:NixOS/nixpkgs/master;

    # Environment/system management
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Flake compat
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };

    # Other sources
    utils.url = github:numtide/flake-utils;
    utils.inputs.systems.follows = "systems";

    emacs.url = github:nix-community/emacs-overlay;
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.flake-utils.follows = "utils";
    comma.url = github:nix-community/comma;
    comma.inputs.nixpkgs.follows = "nixpkgs";
    comma.inputs.flake-compat.follows = "flake-compat";
    comma.inputs.utils.follows = "utils";
#    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.emacs-overlay.follows = "emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    nix-doom-emacs.inputs.flake-utils.follows = "utils";
    nix-doom-emacs.inputs.flake-compat.follows = "flake-compat";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.systems.follows = "systems";
    nix-filter.url = "github:numtide/nix-filter";

    maschine-hacks.url = github:sigma/maschine-hacks;
    maschine-hacks.inputs.systems.follows = "systems";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";

    doom-emacs.url = "github:doomemacs/doomemacs/81f5a8f052045afaa984db42bde7bdfcce16f417";
    doom-emacs.flake = false;
    nix-doom-emacs.inputs.doom-emacs.follows = "doom-emacs";
    nix-doom-emacs.url = github:sigma/nix-doom-emacs/experimental;
  };

  outputs = inputs @ {
    self,
    darwin,
    devshell,
    nix-filter,
    home-manager,
    nixpkgs,
    ...
  }: let
    hosts = import ./hosts.nix {
      inherit (nixpkgs) lib;
    };
    machines = import ./machines.nix {inherit inputs; };
  in
    {
      # My `nix-darwin` configs
      darwinConfigurations = {
        yhodique-macbookpro = machines.mac hosts.yhodique-macbookpro;
        yhodique-macmini = machines.mac hosts.yhodique-macmini;
      };
      inherit (machines) darwinModules;

      # My home-manager only configs
      homeConfigurations = {
        glinux = machines.glinux {};
        shirka = machines.glinux hosts.shirka;
        ghost-wheel = machines.glinux hosts.ghost-wheel;
      };
    } // inputs.utils.lib.eachDefaultSystem (system: {
      packages = let
        default = home-manager.packages.${system}.home-manager;
      in {
        inherit default;
        home-manager = default;
      };

      devShells = let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
            nix-filter.overlays.default
          ];
        };
        default = import ./shell.nix {inherit pkgs; };
      in {
        inherit default;
      };
    });
}
