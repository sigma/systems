{ ... }:
{
  enable = true;
  enableDefaultConfig = false;

  # Note: NixOS hosts automatically get RequestTTY=force and -mux aliases
  # via helpers.nix based on the "nixos" feature flag

  matchBlocks."*" = {
    compression = true;

    controlMaster = "auto";
    controlPath = "~/.ssh/ctrl-%C";
    controlPersist = "yes";

    serverAliveInterval = 30;
    serverAliveCountMax = 3;
  };
}
