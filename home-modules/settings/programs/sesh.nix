{ config, pkgs, ... }:
{
  inherit (config.features.shell) enable;
  enableAlias = false; # alias definition is broken in nushell
  enableTmuxpWorkspaces = true;

  sessions = [
    {
      name = "Second Brain 🧠";
      path = "~/org";
      startupScript = "${pkgs.emacs}/bin/emacsclient -t -e '(org-roam-dailies-goto-today)'";
    }
  ];
}
