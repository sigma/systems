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
      startupScript = "${pkgs.emacs}/bin/emacs -nw -f org-roam-dailies-goto-today";
    }
  ];
}
