{ ... }:
{
  enable = true;
  enableDefaultConfig = false;

  # Force PTY allocation for NixOS hosts to prevent fish shell hangs with VS Code Remote SSH
  # Fish hangs when started interactively without a TTY (ssh -T)
  matchBlocks."shirka" = {
    extraOptions = {
      RequestTTY = "force";
    };
  };

  matchBlocks."*" = {
    compression = true;

    controlMaster = "auto";
    controlPath = "~/.ssh/ctrl-%C";
    controlPersist = "yes";

    serverAliveInterval = 30;
    serverAliveCountMax = 3;
  };
}
