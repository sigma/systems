{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    orbstack.enable = true;
    secretive.enable = true;
    tailscale.enable = true;
  };

  services.emacs.enable = true;
}
