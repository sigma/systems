{
  inputs,
  config,
  ...
}: [
  # Add stable and master package sets for convenience,
  # and x86 variants (for rosetta) for darwin on ARM.
  (import ./pkgsets.nix {inherit inputs config;})

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
