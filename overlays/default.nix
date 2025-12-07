{
  inputs,
  config,
  ...
}:
[
  # Add stable and master package sets for convenience,
  # and x86 variants (for rosetta) for darwin on ARM.
  (import ./pkgsets.nix { inherit inputs config; })

  # community overlays
  inputs.emacs.overlay
  inputs.fenix.overlays.default
  inputs.vscode-extensions.overlays.default

  # utils overlay
  inputs.devshell.overlays.default

  # my overlays
  inputs.maschine-hacks.overlays.default

  # for packages from inputs that don't come with an overlay
  (final: prev: {
    # pkg = inputs.FOO.packages.${final.stdenv.system}.default;
  })

  inputs.noctalia.overlays.default

  # packages hacks
  (import ./pkg)
]
