{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./music.nix
    ./orbstack.nix
    ./secretive.nix
    ./tailscale.nix
  ];

  homebrew.casks = [
    "alfred"
    "google-chrome"
    "notion"
    "notion-calendar"
    "slack"
    "spotify"
    "soundsource"
    "visual-studio-code"
    "whatsapp"
  ];

  programs = {
    aerospace.enable = true;
    karabiner.enable = true;
    music.enable = machine.features.music;
    orbstack.enable = true;
    secretive.enable = true;
    tailscale.enable = true;
  };
}
