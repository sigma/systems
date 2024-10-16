{pkgs, ...}: {
  enable = true;

  sessions = [
    {
      name = "Downloads 📥";
      path = "~/Downloads";
      startupScript = "${pkgs.eza}/bin/eza";
    }
  ];
}
