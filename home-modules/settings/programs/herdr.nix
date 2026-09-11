# herdr configuration (see home-modules/herdr.nix for the module).
#
# On macs herdr comes from Homebrew (darwin-modules/apps/ai.nix), so only the
# config is managed there. On NixOS it is installed from the herdr flake input
# (see overlays/default.nix), which tracks releases more closely than
# nixpkgs-master does. The module writes nothing when disabled.
{ machine, pkgs, ... }:
{
  enable = machine.features.mac || machine.features.nixos;

  package = if machine.features.nixos then pkgs.herdr else null;

  settings = {
    # Skip herdr's first-run notification-setup prompt: notification handling
    # is a choice already made here, and a fresh checkout shouldn't stop on it.
    onboarding = false;

    # Keybindings kept consistent with the tmux config
    # (home-modules/settings/programs/tmux.nix uses `shortcut = "z"`, i.e. a
    # C-z prefix). Many herdr defaults already match tmux (prefix+c new tab,
    # prefix+n/p next/prev, prefix+x close pane, prefix+z zoom); the bindings
    # below are the ones that diverge from tmux muscle memory.
    keys = {
      prefix = "ctrl+z"; # tmux leader
      detach = "prefix+d"; # tmux-style detach (herdr default: prefix+q)
      # tmux default split bindings (herdr defaults are prefix+v / prefix+minus).
      split_vertical = "prefix+%"; # tmux `%` (split-window -h): panes left/right
      split_horizontal = "prefix+\""; # tmux `"` (split-window -v): panes top/bottom
      # Pane focus: tmux navigates with prefix+arrows; keep herdr's hjkl too.
      focus_pane_left = [
        "prefix+h"
        "prefix+left"
      ];
      focus_pane_down = [
        "prefix+j"
        "prefix+down"
      ];
      focus_pane_up = [
        "prefix+k"
        "prefix+up"
      ];
      focus_pane_right = [
        "prefix+l"
        "prefix+right"
      ];
    };

    # catppuccin frappe, to match the rest of the config. herdr ships a single
    # dark "catppuccin" (mocha) built-in with no frappe variant, so frappe is
    # layered on as theme.custom token overrides — the same manual approach
    # used for programs.fish. Only the keys herdr's `config check` accepts are
    # set (panel_bg is herdr's real UI background); the handful it can't
    # override — base, lavender, maroon, pink, sky — are visually near-identical
    # between mocha and frappe, so the result reads as frappe.
    theme = {
      name = "catppuccin";
      custom = {
        panel_bg = "#303446"; # frappe base
        surface0 = "#414559";
        surface1 = "#51576d";
        overlay0 = "#737994";
        overlay1 = "#838ba7";
        text = "#c6d0f5";
        subtext0 = "#a5adce";
        accent = "#ca9ee6"; # mauve (catppuccin default accent)
        mauve = "#ca9ee6";
        red = "#e78284";
        peach = "#ef9f76";
        yellow = "#e5c890";
        green = "#a6d189";
        teal = "#81c8be";
        blue = "#8caaee";
      };
    };

    ui = {
      # Have herdr draw its own cursor (a steady block) instead of delegating
      # to the outer terminal. The default "auto"/"native" policy renders a
      # blinking beam for the focused pane; "drawn" gives a solid, non-blinking
      # block. Note: in every mode herdr renders no cursor for *inactive*
      # panes — there is no config option for a hollow/unfocused-pane cursor.
      host_cursor = "drawn";

      # Tab row along the bottom edge, tmux-style, and out of the way entirely
      # while a workspace only has the one tab.
      tab_bar_position = "bottom";
      hide_tab_bar_when_single_tab = true;

      # Right-aligned status segments, in order.
      tab_bar_right = [
        { type = "zoom"; }
        { type = "hostname"; }
        {
          type = "datetime";
          format = "%H:%M";
        }
      ];

      # Order the agent sidebar by attention priority rather than by workspace.
      agent_panel_sort = "priority";

      # Distinct static symbols for agent state instead of the default colour
      # dots, which only differ by hue.
      status_indicators = "symbols";
    };

    # Reveal a hardware cursor anchor on focused agent panes (claude/pi/codex)
    # that hide it, so native IME candidate windows can follow the pane. Doesn't
    # help inactive-pane cursors, but harmless. Shape is herdr's default block.
    experimental = {
      reveal_hidden_cursor_for_cjk_ime = true;
      cjk_ime_cursor_shape = "steady_block";
    };
  };
}
