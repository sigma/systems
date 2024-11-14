{inputs, ...}: {
  nebula.userRegistry = {
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

  nebula.systemRegistry = {
    nixpkgs.flake = inputs.nixpkgs;
    darwin.flake = inputs.darwin;

    # utils
    flake-parts.flake = inputs.flake-parts;
    flake-compat.flake = inputs.flake-compat;
    flake-utils.flake = inputs.flake-utils;
    flake-root.flake = inputs.flake-root;
    nix-filter.flake = inputs.nix-filter;
    pre-commit-hooks-nix.flake = inputs.pre-commit-hooks-nix;
    treefmt-nix.flake = inputs.treefmt-nix;
    devshell.flake = inputs.devshell;

    # languages
    fenix.flake = inputs.fenix;
  };
}
