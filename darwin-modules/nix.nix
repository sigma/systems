{
  pkgs,
  lib,
  machine,
  ...
}: {
  nix.enable = !machine.features.determinate;

  nix.extraOptions =
    ''
      auto-optimise-store = true
      allow-import-from-derivation = true
      warn-dirty = false
    ''
    + lib.optionalString (pkgs.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';

  programs.nix-index.enable = true;
}
