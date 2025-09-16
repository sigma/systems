{ ... }:
{
  nix.configureBuildUsers = true;

  nix.extraOptions = ''
    auto-optimise-store = true
    allow-import-from-derivation = true
    warn-dirty = false

    extra-experimental-features = nix-command flakes
  '';

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.nix-index.enable = true;
}
