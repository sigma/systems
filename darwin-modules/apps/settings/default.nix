{
  imports = [
    ./aerospace.nix
  ];

  programs = {
    alfred.enable = true;
    chrome.enable = true;
    secretive.enable = true;
  };

  services.emacs.enable = true;
}
