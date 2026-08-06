{ machine, ... }:
{
  imports = [
    ./ipfs.nix
    ./k8s.nix
    ./music.nix
    ./ollama.nix
    ./tailscale.nix
  ];

  features = {
    k8s.enable = machine.features.work;
    music.enable = machine.features.music;
    ipfs.enable = true;
    ollama.enable = machine.features.ollama;
    tailscale.enable = machine.features.tailscale;
  };
}
