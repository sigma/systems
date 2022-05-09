{ config, lib, pkgs, ... }:

{
  home.file.".zsh-plugins/aliases/aliases.plugin.zsh".source = ./aliases.plugin.zsh;

  home.file.".zsh-plugins/directory/directory.plugin.zsh".source = ./directory.plugin.zsh;

  home.file.".zsh-plugins/google/google.plugin.zsh".source = ./google.plugin.zsh;

  home.file.".zsh-plugins/iterm/iterm.plugin.zsh".source = ./iterm.plugin.zsh;

  home.file.".zsh-plugins/utility/utility.plugin.zsh".source = ./utility.plugin.zsh;

  home.file.".zsh-plugins/completion/completion.plugin.zsh".source = ./completion.plugin.zsh;

  home.file.".zsh-plugins/editor/editor.plugin.zsh".source = ./editor.plugin.zsh;

  home.file.".zsh-plugins/history/history.plugin.zsh".source = ./history.plugin.zsh;

  home.file.".zsh-plugins/keys/keys.plugin.zsh".source = ./keys.plugin.zsh;
  home.file.".zsh-plugins/keys/ebindkey".source = ./ebindkey;

  home.file.".zsh-plugins/environment/environment.plugin.zsh".source = ./environment.plugin.zsh;

  home.file.".zsh-plugins/input/input.plugin.zsh".source = ./input.plugin.zsh;

  home.file.".zsh-plugins/less/less.plugin.zsh".source = ./less.plugin.zsh;

  home.file.".p10k.config.zsh".source = ./p10k.config.zsh;
  home.file.".p10k.zsh".source = ./p10k.zsh;
  home.file.".p10k.pure.zsh".source = ./p10k.pure.zsh;
}
