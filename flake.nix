{
  description = "Yann's systems";

  inputs = {
    # Systems
    systems.url = "github:nix-systems/default";

    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    darwin-stable.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    # flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    # Environment/system management
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Personal flakes
    maschine-hacks.url = "github:sigma/maschine-hacks";
    maschine-hacks.inputs.nixpkgs.follows = "nixpkgs";
    maschine-hacks.inputs.flake-parts.follows = "flake-parts";

    # Emacs
    emacs.url = "github:nix-community/emacs-overlay";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.flake-utils.follows = "flake-utils";
    chemacs2nix.url = "github:league/chemacs2nix";
    chemacs2nix.inputs.home-manager.follows = "home-manager";
    chemacs2nix.inputs.emacs-overlay.follows = "emacs";
    chemacs2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";

    # Rust
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    # VS Code
    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    vscode-extensions.inputs.flake-utils.follows = "flake-utils";
    vscode-extensions.inputs.flake-compat.follows = "flake-compat";

    # Utils
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    flake-root.url = "github:srid/flake-root";
    nix-filter.url = "github:numtide/nix-filter";

    # Shell utils
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";
    comma.inputs.flake-compat.follows = "flake-compat";
    comma.inputs.utils.follows = "flake-utils";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixos-stable";
    pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";

    # Theme
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules
      ];

      systems = import inputs.systems;

      perSystem = {
        config,
        system,
        pkgs,
        inputs',
        ...
      }: let
        pkgs' =
          import inputs.nixpkgs {
            inherit system;
          }
          // (import ./pkg-config.nix {
            inherit inputs;
          });
      in {
        _module.args.pkgs = pkgs';

        packages = let
          default = inputs'.home-manager.packages.home-manager;
          localPackages = import ./overlays/pkg/local {
            pkgs = pkgs';
            nix-filter = inputs.nix-filter.lib;
          };
        in
          {
            inherit default;
            home-manager = default;
            darwin-rebuild = inputs'.darwin.packages.darwin-rebuild;
          }
          // localPackages;
      };
    };
}
