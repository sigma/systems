{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    secretive.enable = true;
    tailscale.enable = true;
  };

  services.emacs.enable = true;
}
