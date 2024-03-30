{ inputs, config }:

[
  # Add stable and master package sets for convenience
  (
    final: prev: let
      system = final.stdenv.system;
      nixpkgs-stable =
        if final.stdenv.isDarwin
        then inputs.darwin-stable
        else inputs.nixos-stable;
    in {
      master = inputs.nixpkgs-master.legacyPackages.${system};
      stable = nixpkgs-stable.legacyPackages.${system};
    }
  )

  # silicon package sets
  (import ./silicon.nix inputs config)

  # community overlays
  inputs.comma.overlays.default
  inputs.emacs.overlay
  inputs.fenix.overlays.default

  # utils overlay
  inputs.devshell.overlays.default
  inputs.nix-filter.overlays.default

  # my overlays
  inputs.maschine-hacks.overlays.default

  # packages hacks
  (import ./pkg)
]
