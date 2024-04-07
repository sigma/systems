{ inputs, config }:

[
  # Add stable and master package sets for convenience
  (import ./pkgsets.nix inputs)

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
