{pkgs, ...}: {
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
  programs.zsh.enable = true;

  environment = with pkgs; {
    systemPackages = [
      coreutils-full
      htop
      vim
    ];

    shells = [
      bash
      fish
      zsh
    ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
  };

  security.pam.enableSudoTouchIdAuth = true;
  system.stateVersion = 5;
}
