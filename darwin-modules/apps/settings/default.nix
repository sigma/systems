{machine, ...}: {
  imports = [
    ./aerospace.nix
  ];

  programs = {
    music.enable = machine.features.music;
    orbstack.enable = true;
    secretive.enable = true;
    tailscale.enable = true;
  };

  services.emacs.enable = true;
}
