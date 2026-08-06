{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./alfred.nix
    ./antigravity.nix
    ./brave.nix
    ./claude-code.nix
    ./cursor.nix
    ./karabiner.nix
    ./kurtosis.nix
    ./secretive.nix

    ./settings
  ];

  homebrew.global.brewfile = true;

  homebrew.taps = [
    "oven-sh/bun"
  ];

  homebrew.brews = [
    "container"
    "jj"
    "libusb"
    "opencode"
    "oven-sh/bun/bun"
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
    "yubico-authenticator"
  ];
}
