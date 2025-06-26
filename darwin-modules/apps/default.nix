{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./alfred.nix
    ./brave.nix
    ./karabiner.nix
    ./kurtosis.nix
    ./secretive.nix
    ./tailscale.nix

    ./settings
  ];

  homebrew.global.brewfile = true;

  homebrew.brews = [
    "libusb"
  ];

  homebrew.casks = [
    "calibre"
    "elgato-stream-deck"
    "google-chrome"
    "jordanbaird-ice"
    "notion"
    "notion-calendar"
    "obsidian"
    "slack"
    "spotify"
    "soundsource"
    "visual-studio-code"
    "whatsapp"
    "yubico-yubikey-manager"
  ];
}
