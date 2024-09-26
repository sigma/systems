{machine, ...}: {
  imports = [
    ./aerospace.nix
    ./karabiner.nix
    ./orbstack.nix
    ./secretive.nix
  ];

  programs = {
    aerospace.enable = true;

    karabiner.enable = true;

    # virtualization is not allowed on corp machines
    orbstack.enable = !machine.isWork;

    secretive = {
      enable = true;
      # don't get in the way of gnubby
      globalAgentIntegration = !machine.isWork;
      zshIntegration = !machine.isWork;
    };
  };
}
