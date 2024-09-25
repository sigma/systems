{
  pkgs,
  machine,
  ...
}: {
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    coreutils-full
    htop
    vim
  ];

  environment.shells = with pkgs; [
    bash
    fish
    zsh
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    taps = [
      "nikitabobko/tap" # provides `aerospace`
      "FelixKratz/formulae" # provides `borders`
    ];
    brews = [
      "borders"
    ];
    casks = [
      "aerospace"
      "alfred"
      "google-chrome"
      "karabiner-elements"
      "loopback"
      "notion"
      "notion-calendar"
      "slack"
      "soundsource"
      "spotify"
      "visual-studio-code"
      "wezterm"
      "whatsapp"
    ];
    masApps = {};
    whalebrews = [];
  };

  security.pam.enableSudoTouchIdAuth = !machine.isWork; # this would be overridden by corp.
  system.stateVersion = 5;
}
