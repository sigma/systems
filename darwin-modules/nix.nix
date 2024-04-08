{ pkgs, lib, ...}:
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
    nix.configureBuildUsers = true;

    # Enable experimental nix command and flakes
    # nix.package = pkgs.nixUnstable;
    nix.extraOptions =
      ''
        auto-optimise-store = true
        experimental-features = nix-command flakes
        allow-import-from-derivation = true
      ''
      + lib.optionalString (pkgs.system == "aarch64-darwin") ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';

    # Auto upgrade nix package and the daemon service.
    services.nix-daemon.enable = true;

    nix.package = pkgs.nixFlakes;

    programs.nix-index.enable = true;
  }