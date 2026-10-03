{ machine, ... }:
{
  imports = [
    ./ipfs.nix
    ./k8s.nix
    ./midi-sessions.nix
    ./music.nix
    ./tailscale.nix
    ./voice.nix
  ];

  features = {
    k8s.enable = machine.features.work;
    music.enable = machine.features.music;
    ipfs.enable = true;
    tailscale.enable = machine.features.tailscale;
    voice.enable = machine.features.voice;
  };

  programs.lm-studio.enable = machine.features.llm;
}
