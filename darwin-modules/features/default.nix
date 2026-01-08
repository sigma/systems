{ machine, ... }:
{
  imports = [
    ./ipfs.nix
    ./k8s.nix
    ./music.nix
    ./tailscale.nix
  ];

  features = {
    k8s.enable = machine.features.work;
    music.enable = machine.features.music;
    ipfs.enable = true;
    tailscale.enable = machine.features.tailscale;
  };
}
