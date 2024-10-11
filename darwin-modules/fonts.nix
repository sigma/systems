{pkgs, ...}: {
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    recursive
    source-code-pro
    (master.nerdfonts.override {
      fonts = [
        "FiraCode"
        "SourceCodePro"
        "IntelOneMono"
      ];
    })
  ];
}
