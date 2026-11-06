# Rex — terminal multiplexer (https://www.superlogical.com/rex/).
#
# Upstream's home-manager module (inputs.rex, imported in ../../modules/default.nix)
# owns programs.rex.{enable,package,terminfo,sshGuard,config} and services.rex;
# this file extends programs.rex with `app`, `sessionNaming`, `prefix` and
# `keys`, generates init.lua (programs.rex.config) from the last two, and sets
# the per-platform defaults:
#
#   - Macs: the Rex app runs the server and ships its own CLI, so
#     programs.rex.package is null (upstream then installs nothing, and
#     terminfo/sshGuard default off). The app bundle's CLI dir goes on PATH.
#   - NixOS: the flake's prebuilt package, plus a personal server
#     (services.rex, a systemd user service). nixos-modules/nixos-user.nix
#     turns on linger for it, so it runs from boot and survives logout. On
#     tailscale hosts it is reachable as <host>-rex on the tailnet (below).
#
# It also wires Rex into Claude Code declaratively instead of via
# `rex skill setup --agent claude`. That command writes two things: a stub
# skill (~/.claude/skills/rex) and a SessionStart hook in
# ~/.claude/settings.json. The settings file is a read-only store path here
# (see ../claude-settings-file.nix), so the hook half can never land on its
# own. Both halves are stubs that call `rex` at runtime and carry no version,
# so they are declared below, the way darwin-modules/features/voice.nix points
# at an app bundle it does not build. They match what setup writes, except that
# they call rex by full path (setup relies on PATH), the session-naming flag is
# always explicit (setup omits it when on), and the skill drops setup's "Remove
# it with rex skill remove" comment, which does not apply to a Nix-owned file.
#
# Re-check after a Rex upgrade, against a throwaway HOME:
#   mkdir -p $T/.claude && echo '{}' > $T/.claude/settings.json
#   HOME=$T rex skill setup --agent claude [--session-naming] --autostart=false
{
  config,
  lib,
  machine,
  ...
}:
with lib;
let
  cfg = config.programs.rex;
  claude = config.programs.claude-code;
  naming = "--feature-session-naming=${boolToString cfg.sessionNaming}";
  appBin = "${cfg.app}/Contents/Helpers/Rex Server.rex/Contents/MacOS";
  # May have spaces (the app bundle): quote it wherever it is used.
  rex = if cfg.package != null then getExe cfg.package else "${appBin}/rex";
in
{
  options.programs.rex = {
    app = mkOption {
      type = types.str;
      default = "/Applications/Rex Beta.app";
      description = ''
        Rex application bundle, used when {option}`programs.rex.package` is
        null (the Macs, where the app is installed by hand, not by Nix). The
        skill and hook call its bundled CLI by full path; the CLI's directory
        also goes on PATH for the bare `rex` commands the skill's guide teaches.
      '';
    };

    prefix = mkOption {
      type = types.str;
      default = "ctrl+z";
      description = ''
        Leader key. A {option}`programs.rex.keys` name starting with
        `prefix>` is bound as the sequence this key, then the rest.
      '';
    };

    keys = mkOption {
      type = types.attrsOf (
        types.coercedTo types.str (action: { inherit action; }) (
          types.submodule {
            options = {
              action = mkOption {
                type = types.str;
                description = "Action name, as `rex actions` lists it.";
              };
              args = mkOption {
                type = types.attrsOf types.anything;
                default = { };
                description = "Arguments passed to the action.";
              };
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        {
          "prefix>c" = "client.tab.new";
          "prefix>h" = { action = "pane.focus"; args.direction = "left"; };
        }
      '';
      description = ''
        Key bindings rendered as `rex.bind` calls into the generated
        {option}`programs.rex.config`. A name is a Rex key or `>`-separated
        sequence; a leading `prefix>` stands for {option}`programs.rex.prefix`.
        A string value is shorthand for an action without arguments.
      '';
    };

    sessionNaming = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Tell agents to name the Rex session after their task
        (`rex skill setup --session-naming`).
      '';
    };
  };

  config = mkMerge [
    {
      programs.rex = {
        enable = mkDefault (machine.features.mac || machine.features.nixos);
        package = mkIf machine.features.mac (mkDefault null);
      };
      services.rex.enable = mkDefault machine.features.nixos;

      # tmux-compatible leader layer (tmux and herdr also use C-z, see
      # ../settings/programs/tmux.nix and ./herdr.nix). Only keys that
      # differ from Rex's defaults are bound: its Mac defaults already cover
      # focus (alt+cmd+arrows), zoom (shift+cmd+enter), font size (cmd+=/-/0)
      # and the command palette (shift+cmd+p), so none of those is rebound.
      programs.rex.keys =
        let
          directions = {
            left = [
              "h"
              "left"
            ];
            down = [
              "j"
              "down"
            ];
            up = [
              "k"
              "up"
            ];
            right = [
              "l"
              "right"
            ];
          };
        in
        mkMerge [
          {
            "prefix>${cfg.prefix}" = {
              action = "pane.send_key"; # press the leader twice to send it through
              args.key = cfg.prefix;
            };
            "prefix>c" = "client.tab.new";
            "prefix>shift+7" = "client.tab.close"; # tmux `&`
            "prefix>n" = "client.tab.next";
            "prefix>p" = "client.tab.previous";
            "prefix>shift+5" = {
              action = "pane.split"; # tmux `%`: panes left/right
              args.direction = "right";
            };
            "prefix>shift+'" = {
              action = "pane.split"; # tmux `"`: panes top/bottom
              args.direction = "down";
            };
            "prefix>z" = "pane.zoom";
            "prefix>x" = "pane.close";
            # herdr's popups (./herdr.nix), as floating panes. The same key
            # hides and re-shows them; see ./rex/float-toggle.lua.
            "prefix>t" = {
              action = "float_toggle";
              args.label = "scratch";
            };
            "prefix>shift+j" = {
              action = "float_toggle";
              args = {
                label = "jjui";
                command = [ "jjui" ];
              };
            };
          }
          (genAttrs' (genList (i: i + 1) 9) (i: {
            name = "prefix>${toString i}";
            value = {
              action = "client.tab.goto";
              args.index = i;
            };
          }))
          # Focus on prefix+hjkl/arrows, resize on prefix+ctrl+arrows (tmux).
          (concatMapAttrs (
            direction: keys:
            listToAttrs (
              map (k: {
                name = "prefix>${k}";
                value = {
                  action = "pane.focus";
                  args = { inherit direction; };
                };
              }) keys
            )
            // {
              "prefix>ctrl+${direction}" = {
                action = "pane.resize";
                args = {
                  inherit direction;
                  amount = 5;
                };
              };
            }
          ) directions)
        ];

      # The server joins the tailnet as its own device (Rex embeds Tailscale;
      # the host's tailscaled is not involved), e.g. shirka-rex.<tailnet>.ts.net.
      # Enrolled once by hand: open the sign-in link `rex server status` prints
      # after the first start. The identity then persists in Rex's state dir.
      # Only the enrolling account may connect (allowTailnetMembers stays off).
      services.rex.tailscale = mkIf (machine.features.nixos && machine.features.tailscale) {
        enable = mkDefault true;
        hostname = mkDefault "${machine.alias or machine.name}-rex";
      };
    }

    (mkIf cfg.enable {
      home.sessionPath = mkIf (cfg.package == null) [ appBin ];

      # init.lua is generated: custom actions first, then the bindings.
      programs.rex.config = mkMerge [
        (mkBefore (builtins.readFile ./rex/float-toggle.lua))
        (concatLines (
          mapAttrsToList (
            key: b:
            let
              lua = generators.toLua { multiline = false; };
              k = if hasPrefix "prefix>" key then cfg.prefix + removePrefix "prefix" key else key;
            in
            "rex.bind(${lua k}, ${lua b.action}${optionalString (b.args != { }) ", ${lua b.args}"})"
          ) cfg.keys
        ))
      ];

      # Claude only: the hook below is Claude's, and the skill's guide assumes
      # the session context that hook provides.
      # Both guarded so this does not switch claude-code on where it is off.
      home.file."${claude.configDir}/skills/rex/SKILL.md" = mkIf claude.enable {
        text = ''
          ---
          name: rex
          description: Use the rex CLI to manage Rex sessions, open tabs, arrange panes, run commands, inspect terminal output, and control connected Rex apps.
          metadata:
            rex-stub: "2"
          ---

          Run `"${rex}" __internal skill ${naming}` and follow the guide it prints. The guide comes from
          the installed Rex CLI, so it describes the commands available in that version.

          If the command fails, the installed Rex version predates the guide. Start with
          `rex whoami --json`, then use `rex --help` and `rex COMMAND --help`.
        '';
      };

      programs.claude-code.settings.hooks = mkIf claude.enable {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "/bin/sh -c '\"${rex}\" __internal session-start --agent claude ${naming} 2>/dev/null || true'";
                timeout = 5;
              }
            ];
          }
        ];
      };
    })
  ];
}
