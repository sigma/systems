{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./secretive.nix
  ];

  programs = {
    aerospace.enable = true;

    secretive = {
      enable = true;
      # don't get in the way of gnubby
      globalAgentIntegration = !machine.isWork;
      zshIntegration = !machine.isWork;
    };
  };
}
