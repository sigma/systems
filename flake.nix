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

    # ez-configs
    ez-configs.url = "github:ehllie/ez-configs";
    ez-configs.inputs.nixpkgs.follows = "nixpkgs";
    ez-configs.inputs.flake-parts.follows = "flake-parts";

    # Flake compat
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # Other sources
    utils.url = "github:numtide/flake-utils";
    utils.inputs.systems.follows = "systems";

    emacs.url = "github:nix-community/emacs-overlay";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.flake-utils.follows = "utils";
    comma.url = "github:nix-community/comma";
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
    devshell.inputs.flake-utils.follows = "utils";
    nix-filter.url = "github:numtide/nix-filter";

    maschine-hacks.url = "github:sigma/maschine-hacks";
    maschine-hacks.inputs.systems.follows = "systems";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";

    doom-emacs.url = "github:doomemacs/doomemacs/81f5a8f052045afaa984db42bde7bdfcce16f417";
    doom-emacs.flake = false;
    nix-doom-emacs.inputs.doom-emacs.follows = "doom-emacs";
    nix-doom-emacs.url = "github:sigma/nix-doom-emacs/experimental";
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-lib,
    flake-parts,
    ...
  }: 
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # introduce proper options for homeConfigurations and darwinConfigurations.
        # This is useful mostly during the transition phase from native flake attributes
        # to `ez-configs`, as os configurations get defined in both and need to be merged.
        ./modules/flake-options.nix

        inputs.devshell.flakeModule
        ./modules/shell.nix

        ./modules/legacy-configurations
        inputs.ez-configs.flakeModule
      ];

      systems = import inputs.systems;

      ezConfigs = {
        root = ./.;
        globalArgs = { inherit inputs; };
      };

      perSystem = { config, system, pkgs, inputs', ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = import ./overlays {
            inherit inputs config;
          };
          config = {
            allowUnfree = true;
          };
        };

        packages = let
          default = inputs'.home-manager.packages.home-manager;
        in {
          inherit default;
          home-manager = default;
        };
      };
    };
}
