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

    # pam_u2f's authfile expects ONE line per user with all keys joined by ":".
    # Multiple "user:..." lines silently overwrite each other (only the last
    # one's keyhandle ends up active), so group authorizations by user and
    # emit a single line per user.
    environment.etc."u2f_mappings".text =
      let
        parsed = map (
          s:
          let
            parts = lib.splitString ":" s;
          in
          {
            user = lib.head parts;
            key = lib.concatStringsSep ":" (lib.tail parts);
          }
        ) cfg.authorizations;
        byUser = lib.groupBy (e: e.user) parsed;
        lines = lib.mapAttrsToList (
          user: entries: "${user}:${lib.concatStringsSep ":" (map (e: e.key) entries)}"
        ) byUser;
      in
      lib.concatStringsSep "\n" lines;

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
          ] ++ lib.optionals cfg.verification [ "pinverification=1" ];
          comment = "security.pam.u2f";
        }
      ];
  };
}
