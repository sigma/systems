{ ... }:
{
  nix.extraOptions = ''
    auto-optimise-store = true
    allow-import-from-derivation = true
    warn-dirty = false

    extra-experimental-features = nix-command flakes
  '';

  programs.nix-index.enable = true;
}
