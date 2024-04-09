{
  description = "Yann's systems";

  inputs = {
    # Systems
    systems.url = "path:./flake.systems.nix";
    systems.flake = false;

    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    darwin-stable.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    # flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    # Environment/system management
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Other sources
    emacs.url = "github:nix-community/emacs-overlay";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    nix-filter.url = "github:numtide/nix-filter";

    maschine-hacks.url = "github:sigma/maschine-hacks";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";
    maschine-hacks.inputs.flake-parts.follows = "flake-parts";

    doom-emacs.url = "github:doomemacs/doomemacs/81f5a8f052045afaa984db42bde7bdfcce16f417";
    doom-emacs.flake = false;
    nix-doom-emacs.url = "github:sigma/nix-doom-emacs/experimental";
    nix-doom-emacs.inputs.doom-emacs.follows = "doom-emacs";
    nix-doom-emacs.inputs.emacs-overlay.follows = "emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }: 
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # introduce proper options for homeConfigurations and darwinConfigurations.
        # Also add a defs option for the definitions module below.
        ./modules/flake-options.nix

        # shell support
        ./modules/shell.nix

        # definitions for machine types, hosts, users.
        ./modules/defs

        # configurations for home-manager, darwin, etc.
        ./modules/configurations
      ];

      systems = import inputs.systems;

      perSystem = { config, system, pkgs, inputs', ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
        } // (import ./pkg-config.nix {
          inherit inputs;
        });

        packages = let
          default = inputs'.home-manager.packages.home-manager;
        in {
          inherit default;
          home-manager = default;
        };
      };
    };
}
