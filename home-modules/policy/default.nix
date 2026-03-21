{ lib, machine, ... }:
{
  # Policy modules are gated by machine features. Each entry should be listed
  # in the bucket whose modules it depends on:
  #   - unconditional: only references options from always-loaded home-modules
  #   - workstation-only: references options from modules gated behind
  #     !machine.features.devbox
  imports = lib.optionals (!machine.features.devbox) [
    ./firefly.nix # depends on claude-firefly, claude-glm, gcloud, opencode-firefly
  ];
}
