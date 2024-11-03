{
  imports = [
    ./fish-tide.nix
    ./sesh.nix
  ];

  # use carapace for completions
  programs.carapace.enable = true;
}
