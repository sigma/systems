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

    home.file."bin/gmi-sync" = {
      executable = true;
      text = ''
        #!${pkgs.zsh}/bin/zsh

        SCRIPT_DIR=''${0:a:h}

        ${(builtins.concatStringsSep "\n" (map (prof: ''
        PROFILE_DIR=${config.accounts.email.maildirBasePath}/${prof.name}
        if [ -d "$PROFILE_DIR" ]; then
          cd "$PROFILE_DIR" && ${pkgs.lieer}/bin/gmi pull && "$SCRIPT_DIR/gmi-tag" && ${pkgs.lieer}/bin/gmi push
        fi
        '') user.profiles))}
      '';
    };

    home.file.".config/afew/expire.py".text = ''
    from afew.filters.BaseFilter  import Filter
    from afew.FilterRegistry import register_filter

    @register_filter
    class ExpireFilter(Filter):
      message = 'Expire tagged messages'

      def __init__(self, database, tag="", after=""):
        super().__init__(database)
        self.query = "(tag:%s AND NOT tag:trash AND date:..%s)" % (tag, after)

      def handle_message(self, message):
        self.add_tags(message, 'trash')
    '';

    home.file.".config/afew/kill.py".text = ''
    from afew.filters.KillThreadsFilter import KillThreadsFilter
    from afew.FilterRegistry import register_filter

    @register_filter
    class NewKillThreadsFilter(KillThreadsFilter):

      def __init__(self, database):
        super().__init__(database)
        self.query = "(tag:new AND (%s))" % (self.query)
    '';

    home.file.".config/afew/archive.py".text = ''
    from afew.filters.ArchiveSentMailsFilter import ArchiveSentMailsFilter
    from afew.FilterRegistry import register_filter

    @register_filter
    class NewArchiveSentMailsFilter(ArchiveSentMailsFilter):

      def __init__(self, database):
        super().__init__(database)
        self.query = "(tag:new AND (%s))" % (self.query)
    '';

    home.file."bin/gmi-tag" = {
      executable = true;
      text = ''
      #!${pkgs.zsh}/bin/zsh

      # our config is for all mails
      ${pkgs.afew}/bin/afew --all --tag --verbose "$@"
      '';
    };
  };
}
