{pkgs, ...}: {
  enable = true;
  enableTmuxpWorkspaces = true;

  sessions = [
    {
      name = "Second Brain 🧠";
      path = "~/org";
      startupScript = "${pkgs.emacs}/bin/emacsclient -t -e '(org-roam-dailies-goto-today)'";
    }
  ];
}
