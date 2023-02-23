{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  xdg.configFile."bat/syntaxes/Tmux.sublime-syntax".source = ./Tmux.sublime-syntax;
  xdg.configFile."bat/syntaxes/gomod.sublime-syntax".source = ./gomod.sublime-syntax;
}
