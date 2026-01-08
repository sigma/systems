{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    alfred.enable = true;
    brave.enable = true;
    cursor.enable = true;
    secretive.enable = true;
  };

  services.emacs.enable = true;
}
