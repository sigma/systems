{
  lib,
  machine,
  pkgs,
  ...
}:
{
  imports = [
    ./1password.nix
    ./aerospace.nix
    ./ai.nix
    ./alfred.nix
    ./antigravity-cli.nix
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

  # Tart (devbox hypervisor) comes from nixpkgs: the cirruslabs/cli formula
  # broke on a Homebrew DSL change (`depends_on macos:` outside `on_macos`),
  # and nixpkgs repackages the same signed upstream release binary.
  environment.systemPackages = [ pkgs.tart ];

  homebrew.taps = [
    "oven-sh/bun"
  ];

  homebrew.brews = [
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
