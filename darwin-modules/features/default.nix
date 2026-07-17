{ machine, ... }:
{
  imports = [
    ./ipfs.nix
    ./k8s.nix
    ./llm.nix
    ./midi-sessions.nix
    ./music.nix
    ./tailscale.nix
  ];

  features = {
    k8s.enable = machine.features.work;
    music.enable = machine.features.music;
    ipfs.enable = true;
    llm.enable = machine.features.llm;
    tailscale.enable = machine.features.tailscale;
  };
}
