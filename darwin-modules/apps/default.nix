{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./orbstack.nix
    ./secretive.nix
  ];

  homebrew.casks = [
    "alfred"
    "google-chrome"
    "loopback"
    "notion"
    "notion-calendar"
    "slack"
    "soundsource"
    "spotify"
    "visual-studio-code"
    "whatsapp"
  ];

  programs = {
    aerospace.enable = true;

    karabiner.enable = true;

    # virtualization is not allowed on corp machines
    orbstack.enable = !machine.isWork;

    secretive = {
      enable = true;
      # don't get in the way of gnubby
      globalAgentIntegration = !machine.isWork;
      zshIntegration = !machine.isWork;
    };
  };
}
