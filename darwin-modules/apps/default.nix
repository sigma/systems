{
  lib,
  machine,
  ...
}:
{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./ai.nix
    ./alfred.nix
    ./antigravity.nix
    ./chrome.nix
    ./claude-code.nix
    ./cursor.nix
    ./gemini-cli.nix
    ./kanata.nix
    ./karabiner.nix
    ./kurtosis.nix
    ./secretive.nix

    ./settings
  ];

  programs.gemini-cli.enable = true;

  homebrew.global.brewfile = true;

  homebrew.taps = [
    {
      # Trust the whole tap, not just `tart`: `brew bundle cleanup --force`
      # rewrites the trust store to exactly the Brewfile's `trusted: true`
      # entries, so tart's dependency `cirruslabs/cli/softnet` loses any trust
      # granted out-of-band by `brew trust` on every activation.
      name = "cirruslabs/cli";
      trusted = true;
    }
    "oven-sh/bun"
  ];

  homebrew.brews = [
    "cirruslabs/cli/tart"
    "jj"
    "libusb"
    "oven-sh/bun/bun"
  ]
  ++ lib.optionals machine.features.work [
    "container"
  ];

  homebrew.casks = [
    "calibre"
    "elgato-stream-deck"
    "ghostty"
    "iina"
    "jordanbaird-ice"
    "localsend"
    "obsidian"
    "openusage"
    "soundsource"
    "transnomino"
    "whatsapp"
    "yubico-authenticator"
    "fuse-t"
  ];
}
