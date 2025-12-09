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
    "container"
    "jj"
    "libusb"
    "neovim"
  ];

  homebrew.casks = [
    "calibre"
    "elgato-stream-deck"
    "google-chrome"
    "jordanbaird-ice"
    "localsend"
    "obsidian"
    "soundsource"
    "transnomino"
    "whatsapp"
    "yubico-yubikey-manager"
  ];
}
