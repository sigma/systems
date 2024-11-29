{machine, ...}: {
  imports = [
    ./k8s.nix
    ./music.nix
  ];

  features = {
    k8s.enable = machine.features.work;
    music.enable = machine.features.music;
  };
}
