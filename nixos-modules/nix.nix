{
  machine,
  lib,
  nixConfig,
  ...
}:
{
  nix.settings.trusted-users = [
    "root"
  ];

  nix.extraOptions =
    let
      substituters = lib.concatStringsSep " " nixConfig.trusted-substituters;
      publicKeys = lib.concatStringsSep " " nixConfig.trusted-public-keys;
    in
    ''
      auto-optimise-store = true
      allow-import-from-derivation = true
      warn-dirty = false

      extra-experimental-features = nix-command flakes

      substituters = ${substituters}
      trusted-public-keys = ${publicKeys}
    ''
    + lib.optionalString machine.features.determinate ''
      extra-substituters = https://install.determinate.systems
      extra-trusted-public-keys = cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
    '';

  programs.nix-index.enable = true;
}
