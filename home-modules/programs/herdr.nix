# herdr — terminal agent multiplexer (https://herdr.dev).
#
# Installs herdr (from the pinned upstream flake input, see
# overlays/default.nix) and renders its TOML configuration to
# ~/.config/herdr/config.toml, with the values set below.
{
  config,
  lib,
  pkgs,
  machine,
  ...
}:
with lib;
let
  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.herdr = {
    enable = mkEnableOption "herdr configuration";

    package = mkPackageOption pkgs "herdr" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          keys.prefix = "ctrl+z";
          theme.name = "catppuccin";
        }
      '';
      description = ''
        Configuration written verbatim to {file}`~/.config/herdr/config.toml`.
        See <https://herdr.dev/docs/configuration/> for the full reference, or
        run `herdr --default-config` for the annotated defaults.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression "{ tuicr = pkgs.local.herdr-tuicr-plugin; }";
      description = ''
        herdr plugins to keep linked, keyed by the plugin id declared in each
        directory's `herdr-plugin.toml`. herdr keeps its plugin registry in
        {file}`~/.config/herdr/plugins.json`, which it rewrites itself, so
        these can't be written as config files: activation runs
        `herdr plugin link` for every entry whose registered root differs,
        and unlinks any other plugin rooted in the Nix store (i.e. one this
        option used to declare). See <https://herdr.dev/docs/plugins/>.
      '';
    };
  };

  config = lib.mkMerge [
    # herdr is installed from its upstream flake input (see overlays/default.nix),
    # which tracks releases more closely than nixpkgs-master does. The module
    # writes nothing when disabled.
    {
      programs.herdr =
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
          # as HERDR_BIN_PATH, so the popup talks to the herdr that spawned it.
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
          enable = lib.mkDefault (machine.features.mac || machine.features.nixos);

          # Let each installed roster agent report its state to herdr directly (see
          # ../agents.nix and ./herdr-integrations.nix).
          integrations = lib.pipe config.programs.agents [
            (lib.filterAttrs (_: a: a.installed && a.herdrId != null))
            (lib.mapAttrsToList (_: a: a.herdrId))
          ];

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
              # bundle (home-modules/content/base.nix), but guard anyway so a host without
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
                  width = "90%";
                  height = "90%";
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
        };
    }

    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      # herdr's skills teach agents to drive the multiplexer's panes and sessions.
      programs.agentSkills.plugins = [ pkgs.toolbox.herdr-skills ];

      xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" cfg.settings;

      # `herdr plugin link` registers a plugin whether or not a server is running
      # and a running server picks the change up immediately, so this needs no
      # reload step. Re-linking the same id replaces the previous registration.
      # herdr snapshots the manifest into plugins.json at link time, and every
      # rebuild that touches a plugin yields a new store path, so comparing the
      # registered root against the wanted one is enough to know when to relink.
      home.activation.herdrPlugins = mkIf (cfg.plugins != { }) (
        hm.dag.entryAfter [ "writeBoundary" ] ''
          herdr=${getExe cfg.package}
          registry="${config.xdg.configHome}/herdr/plugins.json"
          have='[]'
          [ ! -s "$registry" ] || have=$(cat "$registry")
          wanted=${escapeShellArg (builtins.toJSON (mapAttrs (_: root: "${root}") cfg.plugins))}
          # Plugins declared here whose registered root is not the wanted one.
          ${getExe pkgs.jq} -nr --argjson have "$have" --argjson wanted "$wanted" '
            ([$have[] | {key: .plugin_id, value: .plugin_root}] | from_entries) as $roots
            | $wanted | to_entries[] | select($roots[.key] != .value) | .value
          ' | while IFS= read -r root; do
            echo "Linking herdr plugin $root"
            run "$herdr" plugin link "$root" > /dev/null
          done
          # Store-rooted plugins no longer declared here: previously ours.
          ${getExe pkgs.jq} -nr --argjson have "$have" --argjson wanted "$wanted" '
            $have[] | select(.source.kind == "local")
            | select(.plugin_root | startswith("${builtins.storeDir}/"))
            | select($wanted[.plugin_id] == null) | .plugin_id
          ' | while IFS= read -r id; do
            echo "Unlinking herdr plugin $id"
            run "$herdr" plugin unlink "$id" > /dev/null
          done
        ''
      );
    })
  ];
}
