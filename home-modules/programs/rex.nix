# Rex — terminal multiplexer (https://www.superlogical.com/rex/).
#
# Upstream's home-manager module (inputs.rex, imported in ../../modules/default.nix)
# owns programs.rex.{enable,package,terminfo,sshGuard,config} and services.rex;
# this file extends programs.rex with `app` and `sessionNaming` and sets the
# per-platform defaults:
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
