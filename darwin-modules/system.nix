{
  config,
  pkgs,
  user,
  ...
}: {
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  environment = with pkgs; {
    systemPackages = [
      coreutils-full
      htop
      vim
    ];

    shells = [
      bash
      fish
    ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
  };

  home-manager.users.${user.login}.programs.fish.interactiveShellInit = ''
    fish_add_path ${config.homebrew.brewPrefix}
  '';

  security.pam.touchid.enable = true;
  security.pam.reattach.package = pkgs.stable.pam-reattach;

  system.stateVersion = 5;
}
