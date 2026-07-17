# Content-feature seam (resolved layer).
#
# Declares options.features.<n>.enable for every content feature in the registry.
# This is the resolved layer of the feature seam: home content gates on
# config.features.<n>.enable rather than on the raw machine.features.<n> input,
# so the devbox policy can override it by priority (mkForce beats the host's
# mkDefault — see modules/nebula/helpers.nix and home-modules/policy/devbox.nix).
{ lib, ... }:
let
  registry = import ../modules/content-features.nix;
in
{
  options.features = lib.genAttrs registry (name: {
    enable = lib.mkEnableOption "content feature: ${name}";
  });
}
