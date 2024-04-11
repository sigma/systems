{pkgs, ...}: {
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    recursive
    (master.nerdfonts.override {fonts = ["SourceCodePro" "IntelOneMono"];})
  ];
}
