{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.ssh;
in
{
  options.services.ssh = {
    enable = mkEnableOption "SSH server (Remote Login)";
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      echo >&2 "enabling SSH server (Remote Login)..."
      launchctl enable system/com.openssh.sshd
      launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    '';
  };
}
