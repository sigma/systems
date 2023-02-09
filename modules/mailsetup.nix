{ user, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.mailsetup;

  pkg = pkgs.stdenv.mkDerivation rec {
    pname = "gmi";
    version = "v0.1";

    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin

      cat >> $out/bin/gmi-sendmail << 'EOF'
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
      EOF

      cat >> $out/bin/gmi-sync << 'EOF'
      #!${pkgs.zsh}/bin/zsh

      SCRIPT_DIR=''${0:a:h}

      ${(builtins.concatStringsSep "\n" (map (prof: ''
      PROFILE_DIR=${config.accounts.email.maildirBasePath}/${prof.name}
      if [ -d "$PROFILE_DIR" ]; then
        cd "$PROFILE_DIR" && ${pkgs.lieer}/bin/gmi pull && "$SCRIPT_DIR/gmi-tag" && ${pkgs.lieer}/bin/gmi push
        fi
      '') user.profiles))}
      EOF

      cat >> $out/bin/gmi-tag << 'EOF'
      #!${pkgs.zsh}/bin/zsh

      # our config is for all mails
      ${pkgs.afew}/bin/afew --all --tag --verbose "$@"
      EOF

      chmod a+x $out/bin/gmi-*
    '';
  };

in
{
  options.programs.mailsetup = {
    enable = mkEnableOption "mailsetup";

    startInterval = mkOption {
      type = types.nullOr types.int;
      default = 60;
      description = "Optional key to start gmi services each N seconds";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkg];

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

    launchd.agents.gmi-sync = {
      enable = true;
      config = {
        ProgramArguments = [ "${pkg}/bin/gmi-sync" ];
        KeepAlive = false;
        RunAtLoad = true;
        StartInterval = 60;
        StandardOutPath = "/var/log/gmi/gmi.log";
        StandardErrorPath = "/var/log/gmi/gmi.log";
      };
    };
  };
}
