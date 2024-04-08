{
  pkgs,
  ...
}: {
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs;
    [
      coreutils
      htop
      vim
    ];

  environment.shells = with pkgs; [
    bash
    fish
    zsh
  ];  
}
