{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.security.pam.reattach;
in {
  options.security.pam.reattach = {
    enable = mkEnableOption "reattach PAM module";

    package = mkOption {
      type = types.package;
      default = pkgs.pam-reattach;
      description = "The pam-reattach package to use.";
    };
  };

  config = mkIf cfg.enable {
    security.pam.sudo_local.entries = mkBefore [
      {
        module = "${cfg.package}/lib/pam/pam_reattach.so";
        comment = "security.pam.reattach";
      }
    ];
  };
}
