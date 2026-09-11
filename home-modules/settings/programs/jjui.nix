# jjui configuration. home-manager's programs.jjui renders it; the `themes`
# option and the catppuccin-derived `ui.theme` come from home-modules/jjui.nix.
#
# jjui is installed everywhere via the vcs-toolchain bundle, so the config is
# enabled everywhere too (matches tuicr).
_: {
  enable = true;

  # jjui ships in the toolbox's vcs-toolchain bundle (home-modules/default.nix);
  # installing it again would collide on `bin/jjui`.
  package = null;

  # Fuzzy matching for the `:` (exec) and `$` prompts' suggestions.
  settings.suggest.exec.mode = "fuzzy";
}
