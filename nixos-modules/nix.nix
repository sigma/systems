{ machine, lib, ... }:
{
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
