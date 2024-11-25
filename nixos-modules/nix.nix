{ machine, lib, ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos.org/"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
  nix.settings.trusted-users = [
    "root"
  ];

  nix.extraOptions = ''
    auto-optimise-store = true
    allow-import-from-derivation = true
    warn-dirty = false

    extra-experimental-features = nix-command flakes
  ''
  + lib.optionalString machine.features.determinate ''
    lazy-trees = true
    eval-cores = 0 # Evaluate across all cores
    extra-substituters https://install.determinate.systems
    extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
  '';

  programs.nix-index.enable = true;
}
