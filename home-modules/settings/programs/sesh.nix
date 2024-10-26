{pkgs, ...}: {
  enable = true;

  sessions = [
    {
      name = "Downloads 📥";
      path = "~/Downloads";
      startupScript = "${pkgs.eza}/bin/eza";
    }
    {
      name = "Second Brain 🧠";
      path = "~/org";
      startupScript = "${pkgs.emacs}/bin/emacsclient -t -e '(org-roam-dailies-goto-today)'";
    }
  ];
}
