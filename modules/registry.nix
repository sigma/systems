{ inputs, lib, ... }:
let
  userRegistryModule = {
    nix.registry = {
      microvm.to = {
        type = "github";
        owner = "astro";
        repo = "microvm.nix";
      };
      nixos-shell.to = {
        type = "github";
        owner = "Mic92";
        repo = "nixos-shell";
      };
    };
  };

  systemRegistryModule = {
    nix.registry = lib.mkForce {
      # systems
      systems.flake = inputs.systems;
      nixpkgs.flake = inputs.nixpkgs;
      darwin.flake = inputs.darwin;

      # utils
      flake-parts.flake = inputs.flake-parts;
      flake-compat.flake = inputs.flake-compat;
      flake-utils.flake = inputs.flake-utils;
      flake-root.flake = inputs.flake-root;
      pre-commit-hooks-nix.flake = inputs.pre-commit-hooks-nix;
      treefmt-nix.flake = inputs.treefmt-nix;
      devshell.flake = inputs.devshell;

      # languages
      fenix.flake = inputs.fenix;
    };
  };
in
{
  nebula.homeModules = [
    userRegistryModule
  ];

  nebula.linuxModules = [
    systemRegistryModule
  ];

  nebula.nixosModules = [
    (
      { machine, lib, ... }:
      {
        imports = lib.optionals machine.features.determinate [ inputs.determinate.nixosModules.default ];
      }
    )
    systemRegistryModule
  ];

  nebula.darwinModules = [
    systemRegistryModule
  ];
}
