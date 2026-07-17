# television (tv) — the primary interactive fuzzy finder.
#
# fzf is intentionally kept alongside tv for the tools tv can't replace:
# the fzf-fish widgets (Ctrl+Alt+F/L/S/P, Ctrl+V), tmux-fzf, fzf-tmux-url,
# zoxide's `zi`, and neovim's telescope-fzf-native (the fzf algorithm as a
# library). See home-modules/settings/programs/fzf.nix.
#
# Shell integration binds Ctrl+T (smart autocomplete). tv also binds Ctrl+R
# to its own history, but atuin owns Ctrl+R here, so home-modules/television.nix
# hands Ctrl+R back to atuin after tv loads. nushell integration is wired
# there too (this HM version's module only supports fish/bash/zsh).
{ config, pkgs, ... }:
{
  enable = config.features.shell.enable;

  # Default/stable nixpkgs pin tv 0.13.10, which is too old to parse the
  # current config schema and shell-init format. Track master for a recent
  # release (0.15.x).
  package = pkgs.master.television;

  enableFishIntegration = true;
}
