{pkgs, ...}: {
  enable = true;
  config = {
    theme = "OneHalfDark";
    style = "numbers,changes,header";
    italic-text = "always";
    map-syntax = [
      "jsonnet:json"
      "libsonnet:json"
      "bazel:py"
      "BUILD:py"
      "WORKSPACE:py"
    ];
  };
  extraPackages = with pkgs.bat-extras; [batdiff batman batgrep batwatch batpipe prettybat];
}
