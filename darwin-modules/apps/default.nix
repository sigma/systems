{machine, ...}: {
  imports = [
    ./secretive.nix
  ];

  programs.secretive = {
    enable = true;
    # don't get in the way of gnubby
    globalAgentIntegration = !machine.isWork;
    zshIntegration = !machine.isWork;
  };
}
