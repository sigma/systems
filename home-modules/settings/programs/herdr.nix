# herdr configuration (see home-modules/herdr.nix for the module).
#
# On macs herdr comes from Homebrew (darwin-modules/apps/ai.nix), so only the
# config is managed there. On NixOS it is installed from the herdr flake input
# (see overlays/default.nix), which tracks releases more closely than
# nixpkgs-master does. The module writes nothing when disabled.
{
  config,
  lib,
  machine,
  pkgs,
  ...
}:
let
  # Persistent scratch terminal for the `prefix+t` popup. herdr popups only
  # live until their command exits and every herdr terminal has to sit in a
  # tab, so there is no native hide/re-show; the state is kept in a tmux
  # session instead. `new-session -A` attaches when the session exists and
  # creates it otherwise, so detaching (C-z d) closes the popup while the
  # shell, jobs and scrollback keep running — and outlive herdr restarts.
  # Sessions are keyed on the workspace label (nix, trunk, ...), which is
  # meaningful and stable across restarts unlike the w0-style IDs; the ID is
  # the fallback when the label can't be read. herdr hands its own binary over
  # as HERDR_BIN_PATH, which keeps this working on macOS where herdr is not a
  # nix package.
  scratch = pkgs.writeShellApplication {
    name = "herdr-scratch";
    runtimeInputs = [
      config.programs.tmux.package
      pkgs.jq
    ];
    text = ''
      label=""
      if [ -n "''${HERDR_BIN_PATH:-}" ] && [ -n "''${HERDR_ACTIVE_WORKSPACE_ID:-}" ]; then
        label=$("$HERDR_BIN_PATH" workspace get "$HERDR_ACTIVE_WORKSPACE_ID" 2>/dev/null \
          | jq -r '.result.workspace.label // empty' || true)
      fi
      name="scratch-''${label:-''${HERDR_ACTIVE_WORKSPACE_ID:-default}}"
      # tmux session names can't contain `.` or `:`.
      name=$(printf '%s' "$name" | tr '.:' '__')
      cd "''${HERDR_ACTIVE_PANE_CWD:-$HOME}" || true
      exec tmux new-session -A -s "$name"
    '';
  };
in
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

      # Custom commands. `prefix+shift+j` ("J" for jj) is unbound in herdr's
      # defaults and above, and mirrors herdr's own `prefix+alt+g` lazygit
      # example without depending on Option-key handling on macOS. Popups run
      # via `/bin/sh -c` and don't inherit the pane's cwd, so hop into it via
      # HERDR_ACTIVE_PANE_CWD. jjui normally ships with the vcs-toolchain
      # bundle (home-modules/default.nix), but guard anyway so a host without
      # it gets a message instead of a popup that flashes and vanishes.
      command = [
        {
          key = "prefix+shift+j";
          type = "popup";
          description = "jjui (jj TUI)";
          command = ''
            cd "''${HERDR_ACTIVE_PANE_CWD:-.}" && if command -v jjui >/dev/null 2>&1; then exec jjui; else echo "jjui is not installed"; read -r _; fi
          '';
          width = "90%";
          height = "90%";
        }
        # `prefix+t` is the key herdr's own scratch-terminal example uses and is
        # unbound in the defaults (tmux binds it to a clock, nothing lost).
        {
          key = "prefix+t";
          type = "popup";
          description = "scratch terminal (per-workspace tmux; C-z d to hide)";
          command = lib.getExe scratch;
          width = "80%";
          height = "80%";
        }
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
