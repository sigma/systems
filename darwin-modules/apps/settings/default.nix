{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    brave.enable = true;
    secretive.enable = true;
    tailscale.enable = true;
  };

  services.emacs.enable = true;
}
