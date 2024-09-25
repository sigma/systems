{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./secretive.nix
  ];

  programs = {
    aerospace.enable = true;

    karabiner.enable = true;

    secretive = {
      enable = true;
      # don't get in the way of gnubby
      globalAgentIntegration = !machine.isWork;
      zshIntegration = !machine.isWork;
    };
  };
}
