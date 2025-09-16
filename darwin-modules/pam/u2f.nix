{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.security.pam.u2f;
in
{
  options.security.pam.u2f = {
    enable = mkEnableOption "U2F PAM module";

    package = mkOption {
      type = types.package;
      default = pkgs.pam_u2f;
      description = "The PAM U2F package to use.";
    };

    authorizations = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of authorizations for the module.";
    };

    secondFactor = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to require as a second factor.";
    };

    verification = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to verify the U2F token.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.authorizations != [ ];
        message = ''
          security.pam.u2f.authorizations must not be empty.
          Populate with the output of ${pkgs.pam_u2f}/bin/pamu2fcfg
        '';
      }
    ];

    environment.etc."u2f_mappings".text = lib.concatStringsSep "\n" cfg.authorizations;

    security.pam.reattach.enable = true;
    security.pam.sudo_local.entries =
      let
        control = if cfg.secondFactor then "required" else "sufficient";
      in
      [
        {
          control = control;
          module = "${cfg.package}/lib/security/pam_u2f.so";
          arguments = [
            "authfile=/etc/u2f_mappings"
            "cue"
            (if cfg.verification then "pinverification=1" else "")
          ];
          comment = "security.pam.u2f";
        }
      ];
  };
}
