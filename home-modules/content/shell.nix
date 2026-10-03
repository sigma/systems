# `shell` content feature: interactive shell power-user toolkit (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.shell.enable {
  home.packages = with pkgs; [
    # console tools
    ast-grep
    broot
    btop
    chafa
    d2
    glow
    gum
    hexyl
    pinfo
    procs
    rm-improved
    safe-rm
    silver-searcher
    soft-serve
    tealdeer

    # json/yaml helpers
    jsonnet
    jsonnet-bundler
  ];
}
