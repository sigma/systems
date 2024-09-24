{
  lib,
  machine,
  user,
  ...
}:
{
  enable = true;

  compression = true;

  controlMaster = "auto";
  controlPath = "~/.ssh/ctrl-%C";
  controlPersist = "yes";

  serverAliveInterval = 30;
  serverAliveCountMax = 3;
}
// lib.optionalAttrs (builtins.hasAttr "sshMatchBlocks" machine) {
  matchBlocks = machine.sshMatchBlocks;
}
// lib.optionalAttrs (machine.isMac) {
  extraConfig = ''
    IdentityAgent /Users/${user.login}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  '';
}
