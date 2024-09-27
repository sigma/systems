{
  machine,
  lib,
  ...
}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./orbstack.nix
    ./secretive.nix
  ];

  homebrew.casks =
    [
      "alfred"
      "google-chrome"
      "notion"
      "notion-calendar"
      "slack"
      "spotify"
      "visual-studio-code"
      "whatsapp"
    ]
    ++ lib.optionals machine.features.music [
      "loopback"
      "soundsource"
    ];

  programs = {
    aerospace.enable = true;
    karabiner.enable = true;
    orbstack.enable = true;
    secretive.enable = true;
  };
}
