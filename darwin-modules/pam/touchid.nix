# This module applies only starting with Sonoma (14.5)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.security.pam;
in {
  options.security.pam = {
    enableReattachedSudoTouchIdAuth = mkEnableOption ''
      Enable sudo authentication with Touch ID
      When enabled, this option adds the following line to /etc/pam.d/sudo_local:
          auth       optional       /path/to/pam_reattach.so
          auth       sufficient     pam_tid.so
    '';

    reattachPackage = mkOption {
      type = types.package;
      default = pkgs.pam-reattach;
      description = "The pam-reattach package to use.";
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enableReattachedSudoTouchIdAuth && cfg.enableSudoTouchIdAuth);
        message = "enableReattachedSudoTouchIdAuth and enableSudoTouchIdAuth cannot be enabled at the same time";
      }
    ];

    security.pam.sudo_local.entries = let
      comment = "security.pam.enableReattachedSudoTouchIdAuth";
    in [
      {
        module = "${cfg.reattachPackage}/lib/pam/pam_reattach.so";
        inherit comment;
      }
      {
        control = "sufficient";
        module = "pam_tid.so";
        inherit comment;
      }
    ];
  };
}
