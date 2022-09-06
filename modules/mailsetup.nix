{ user, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.mailsetup;
in
{
  options.programs.mailsetup = {
    enable = mkEnableOption "mailsetup";
  };

  config = mkIf cfg.enable {
    home.file."bin/gmi-sendmail" = {
      executable = true;
      text = ''
        #!${pkgs.zsh}/bin/zsh

        MAIL=$(${pkgs.coreutils}/bin/mktemp)
        trap '{ rm -f -- "$MAIL"; }' EXIT
        tee "$MAIL" >/dev/null

        FROM=$(${pkgs.procmail}/bin/formail -x From: -c < "$MAIL")
        PROFILE=""

        ${(builtins.concatStringsSep "\n" (map (prof: ''
        if [[ "$FROM" =~ "(${builtins.concatStringsSep "|" prof.emails})" ]]; then
          PROFILE=${prof.name}
        fi
        '') user.profiles))}

        if [ -z "$PROFILE" ]; then
          echo "invalid From address: $FROM" >/dev/stderr
          exit 1
        fi

        exec ${pkgs.lieer}/bin/gmi send --quiet -t -C "${config.accounts.email.maildirBasePath}/$PROFILE" < "$MAIL"
        '';
    };
  };
}
