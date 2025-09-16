{ ... }:
{
  enable = true;

  compression = true;

  controlMaster = "auto";
  controlPath = "~/.ssh/ctrl-%C";
  controlPersist = "yes";

  serverAliveInterval = 30;
  serverAliveCountMax = 3;
}
