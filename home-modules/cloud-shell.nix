{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cloudshell;
in {
  options.programs.cloudshell = {
    enable = mkEnableOption "cloudshell utils";
  };

  config = mkIf cfg.enable {
    home.file.".ssh/cloudshell_proxy" = {
      text = ''
        #!/usr/bin/env bash
        set -e

        CONFIG=''${1:-default}

        SSH_CMD=$(${pkgs.google-cloud-sdk}/bin/gcloud --configuration="$CONFIG" cloud-shell ssh --dry-run 2>/dev/null | tail -1)

        PORT="6000" # This seems to be the default port for ssh on those VMs.
        HOST=""

        set -- $SSH_CMD

        for arg ; do
          shift
          case $arg in
            -p)
              PORT="$1"
              ;;
            *@*)
              HOST="''${arg#*@}"
          esac
        done

        exec ${pkgs.nmap}/bin/ncat "$HOST" "$PORT"
      '';

      executable = true;
    };
  };
}
