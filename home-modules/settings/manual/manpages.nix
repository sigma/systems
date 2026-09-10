# home-manager's option-reference manpage (`man home-configuration.nix`).
#
# Building it evaluates the whole home-manager option set and renders it through
# nixosOptionsDoc, which emits an `options.json` derivation carrying a
# context-free nixpkgs store path — a noisy eval warning on every rebuild. We
# read the options online instead, so the manpage is not worth the noise.
{ ... }:
{
  enable = false;
}
