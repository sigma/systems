{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    alfred.enable = true;
    brave.enable = true;
    secretive.enable = true;
    tailscale.enable = true;

    flox.enable = true;
  };

  services.emacs.enable = true;
}
