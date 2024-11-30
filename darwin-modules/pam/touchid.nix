# This module applies only starting with Sonoma (14.5)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.security.pam.touchid;
in {
  options.security.pam.touchid = {
    enable = mkEnableOption ''
      Enable sudo authentication with Touch ID
      When enabled, this option adds the following line to /etc/pam.d/sudo_local:
          auth       sufficient     pam_tid.so
    '';
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && config.security.pam.enableSudoTouchIdAuth);
        message = "config.security.pam.touchid.enable and config.security.pam.enableSudoTouchIdAuth cannot be enabled at the same time";
      }
    ];

    security.pam = mkIf cfg.enable {
      reattach.enable = true;

      sudo_local.entries = mkOrder 600 [
        {
          control = "sufficient";
          module = "pam_tid.so";
          comment = "security.pam.touchid";
        }
      ];
    };
  };
}
