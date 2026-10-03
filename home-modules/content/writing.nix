# `writing` content feature: authoring tools (see CONTEXT.md).
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.features.writing.enable {
  home.packages = with pkgs; [
    hugo
    mdbook
    mdbook-mermaid
  ];
}
