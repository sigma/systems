{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./karabiner.nix
    ./orbstack.nix
    ./secretive.nix
    ./tailscale.nix

    ./settings
  ];

  homebrew.casks = [
    "alfred"
    "calibre"
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
}
