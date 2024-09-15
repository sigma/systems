{pkgs, ...}: {
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    recursive
    (master.nerdfonts.override {
      fonts = [
        "FiraCode"
        "SourceCodePro"
        "IntelOneMono"
      ];
    })
  ];
}
