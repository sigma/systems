{
  pkgs,
  lib,
  machine,
  user,
  nixConfig,
  ...
}:
{
  nix.enable = !machine.features.determinate;

  nix.extraOptions =
    let
      substituters = lib.concatStringsSep " " nixConfig.trusted-substituters;
      publicKeys = lib.concatStringsSep " " nixConfig.trusted-public-keys;
    in
    ''
      auto-optimise-store = true
      allow-import-from-derivation = true
      warn-dirty = false

      substituters = ${substituters}
      trusted-public-keys = ${publicKeys}
    ''
    + lib.optionalString (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';

  programs.nix-index.enable = true;

  system.primaryUser = user.login;
}
