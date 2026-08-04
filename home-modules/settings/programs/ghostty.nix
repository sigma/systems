# Ghostty terminal configuration.
#
# Ghostty is installed via the Homebrew cask on macOS (darwin-modules/apps),
# so `package = null` here — home-manager only writes the config file. The
# catppuccin theme (frappe) is applied automatically via catppuccin.ghostty,
# mirroring the wezterm setup.
#
# Font settings are derived from the shared terminal font profile
# (home-modules/settings/programs/fontProfiles.nix), the exact same source
# wezterm reads, so the two terminals stay aligned.
{
  config,
  lib,
  machine,
  ...
}:
let
  term = config.programs.fontProfiles.terminal;

  # Normalize the mixed fallback list (font objects + bare strings) the same
  # way wezterm.nix does.
  fbName = f: if lib.isString f then f else f.family;

  # Ghostty selects a face by style name; map the profile weight to Fira Code's
  # named instance (600 -> "SemiBold", wezterm's "DemiBold" equivalent).
  weightToStyle =
    w:
    {
      "300" = "Light";
      "400" = "Regular";
      "500" = "Medium";
      "600" = "SemiBold";
      "700" = "Bold";
    }
    .${toString w} or "Regular";
in
{
  enable = machine.features.mac;
  package = null; # provided by the Homebrew cask on darwin

  settings = {
    # Primary family first, then the shared fallbacks (nerd font, then system).
    font-family = [ term.family.family ] ++ map fbName term.fallbacks;
    font-size = term.size;
    font-feature = term.features;

    # Solid block cursor that never blinks. `no-cursor` stops the shell
    # integration (fish) from switching the shape to a beam — without it the
    # block setting is overridden at the prompt.
    cursor-style = "block";
    cursor-style-blink = false;
    shell-integration-features = "no-cursor";
  }
  // lib.optionalAttrs (term.weight != null) {
    font-style = weightToStyle term.weight;
  };
}
