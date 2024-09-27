{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./music.nix
    ./orbstack.nix
    ./secretive.nix
  ];

  homebrew.casks = [
    "alfred"
    "google-chrome"
    "notion"
    "notion-calendar"
    "slack"
    "spotify"
    "tailscale"
    "visual-studio-code"
    "whatsapp"
  ];

  programs = {
    aerospace.enable = true;
    karabiner.enable = true;
    music.enable = machine.features.music;
    orbstack.enable = true;
    secretive.enable = true;
  };
}
