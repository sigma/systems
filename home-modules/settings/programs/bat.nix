{pkgs, ...}: {
  enable = true;
  config = {
    style = "numbers,changes,header";
    italic-text = "always";
    map-syntax = [
      "*.jsonnet:JSON"
      "*.libsonnet:JSON"
      "*.bazel:Python"
      "BUILD:Python"
      "WORKSPACE:Python"
      "flake.lock:JSON"
    ];
  };
  extraPackages = with pkgs.bat-extras; [batdiff batman batgrep batwatch batpipe prettybat];
  syntaxes = let
    sublime-gomod = pkgs.fetchFromGitHub {
      owner = "mitranim";
      repo = "sublime-gomod";
      rev = "eed77270079a9adcc1b313b8c3163ef9cee98847";
      sha256 = "sha256-BOqGcYepYruc1sq2kOpQ7jJUOwnNNcu3fmAoYYzj3Bc=";
    };
  in {
    gomod = {
      src = sublime-gomod;
      file = "Gomod.sublime-syntax";
    };
    gosum = {
      src = sublime-gomod;
      file = "Gosum.sublime-syntax";
    };
    tmux = {
      src = pkgs.fetchFromGitHub {
        owner = "gerardroche";
        repo = "sublime-tmux";
        rev = "c7c6891698b752d5c6050929e4896bb8caa608ae";
        sha256 = "sha256-c7WJOmrYi8MLCU19O8KGNfV7YxSO+SdVmxtwsdkIxtQ=";
      };
      file = "Tmux.sublime-syntax";
    };
  };
}
