{machine, ...}: {
  imports = [
    ./music.nix
  ];

  features = {
    music.enable = machine.features.music;
  };
}
