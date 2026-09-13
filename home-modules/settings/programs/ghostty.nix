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

    # Fullscreen without the macOS animation/space dance, keeping the window
    # clear of the notch. Native tabs don't work in this mode — splits and
    # herdr do the multiplexing here, so that's not a loss.
    macos-non-native-fullscreen = "padded-notch";

    # Window chrome mirrored from wezterm (appearance.lua): same asymmetric
    # padding (left,right / top,bottom), no titlebar, no close prompt.
    window-padding-x = "12,10";
    window-padding-y = "12,7";
    window-padding-balance = true;
    macos-titlebar-style = "hidden";
    confirm-close-surface = false;
    window-save-state = "always";

    # Dim unfocused splits like wezterm's inactive_pane_hsb brightness.
    unfocused-split-opacity = 0.65;

    # No audible bell; keep the dock-bounce when unfocused (wezterm used a
    # visual-only bell).
    bell-features = "no-system,attention";

    # Left option is Alt for shell/editor bindings, right option still
    # composes accented characters (wezterm's
    # send_composed_key_when_right_alt_is_pressed).
    macos-option-as-alt = "left";

    mouse-hide-while-typing = true;
    cursor-click-to-move = true;

    # Split navigation on the same chords as wezterm (bindings.lua):
    # cmd+arrows move, cmd+shift+arrows resize, cmd+enter zoom.
    keybind = [
      "super+up=goto_split:up"
      "super+down=goto_split:down"
      "super+left=goto_split:left"
      "super+right=goto_split:right"
      "super+shift+up=resize_split:up,3"
      "super+shift+down=resize_split:down,3"
      "super+shift+left=resize_split:left,3"
      "super+shift+right=resize_split:right,3"
      "super+enter=toggle_split_zoom"
    ];
  }
  // lib.optionalAttrs (term.weight != null) {
    font-style = weightToStyle term.weight;
  };
}
