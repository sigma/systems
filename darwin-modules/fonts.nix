{pkgs, ...}: {
  fonts.packages = with pkgs; [
    recursive
    (master.nerdfonts.override {fonts = ["SourceCodePro" "IntelOneMono"];})
  ];
}
