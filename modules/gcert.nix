{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gcert;
in
{
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

  config = mkIf cfg.enable {
    home.file.".ssh/${cfg.ssh_include}".text = let
      gcertstatus = "${cfg.package}/bin/gcertstatus";
      gcert = "${cfg.package}/bin/gcert";
      gcert_renew = "open -W -n ${cfg.package}/bin/gcert_renew.command";
    in ''
      #######
      # Ensure we have gcert
      # https://yaqs.corp.google.com/eng/q/6704876541837312
      Match host *.corp.google.com,*.c.googlers.com exec "${gcertstatus} --check_remaining=1h --quiet || ( ( [[ $- =~ i ]] && ${gcert}) || ( [[ ! $- =~ i ]] && ${gcert_renew} ) ) || true"

      # That blank line is required; we're executing that for the gcert side effects, not to set any ssh parameters.
      '';

    programs.ssh.includes = [
      "~/.ssh/${cfg.ssh_include}"
    ];
  };
}
