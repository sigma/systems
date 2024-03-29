{
  config,
  lib,
  pkgs,
  machine,
  ...
}:
with lib; let
  cfg = config.programs.gcert;
in {
  options.programs.gcert = {
    enable = mkEnableOption "gcert - google certificate manager";

    package = mkOption {
      type = types.package;
      default = pkgs.gcert;
    };

    ssh_include = mkOption {
      type = types.str;
      default = "gcert.include";
    };
  };

  config = mkIf cfg.enable (let
    glinux = machine.isWork && machine.system == "x86_64-linux";
    gcertstatus = "${cfg.package}/bin/gcertstatus";
    gcert = "${cfg.package}/bin/gcert";
  in {
    home.file =
      {
        ".ssh/${cfg.ssh_include}".text = ''
          #######
          # Ensure we have gcert
          Match host *.corp.google.com,*.c.googlers.com exec "find /var/run/ccache/sso-$USER/cookie ~/.sso/cookie -mmin -1200 2>/dev/null | grep -q . && ${gcertstatus} --check_remaining=1h --nocheck_loas2 --quiet || ${gcert} --noloas2"

          # That blank line is required; we're executing that for the gcert side effects, not to set any ssh parameters.
        '';
      }
      // lib.optionalAttrs glinux {
        ".ssh/rc".text = ''
          ${gcertstatus} --nocheck_ssh --check_remaining=1h --quiet || ${gcert} --nocorpssh
        '';
      };

    programs.ssh.includes = [
      "~/.ssh/${cfg.ssh_include}"
    ];
  });
}
