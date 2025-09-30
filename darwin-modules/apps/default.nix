{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./alfred.nix
    ./brave.nix
    ./cursor.nix
    ./karabiner.nix
    ./kurtosis.nix
    ./secretive.nix
    ./tailscale.nix

    ./settings
  ];

  homebrew.global.brewfile = true;

  homebrew.brews = [
    "jj"
    "libusb"
  ];

  homebrew.casks = [
    "calibre"
    "elgato-stream-deck"
    "google-chrome"
    "jordanbaird-ice"
    "linear-linear"
    "notion"
    "notion-calendar"
    "obsidian"
    "slack"
    "soundsource"
    "whatsapp"
    "yubico-yubikey-manager"
  ];
}
