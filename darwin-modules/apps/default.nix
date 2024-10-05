{machine, ...}: {
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./karabiner.nix
    ./music.nix
    ./orbstack.nix
    ./secretive.nix
    ./tailscale.nix
  ];

  homebrew.casks = [
    "alfred"
    "elgato-stream-deck"
    "google-chrome"
    "notion"
    "notion-calendar"
    "slack"
    "spotify"
    "soundsource"
    "visual-studio-code"
    "whatsapp"
    "yubico-yubikey-manager"
  ];

  programs = {
    aerospace.enable = true;
    music.enable = machine.features.music;
    orbstack.enable = true;
    secretive.enable = true;
    tailscale.enable = true;
  };
}
