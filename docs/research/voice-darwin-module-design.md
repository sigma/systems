# Design: `darwin-modules/features/voice.nix` (cask + Claude Code hook wiring)

Design output for **nix-4t3.3** (map: nix-4t3 — Voice: wire Claude Code to SuperWhisper).
Builds on the nix-4t3.1 binary research and the nix-4t3.2 feature-seam model. The
actual module is written & activated in **nix-4t3.6**; this is the blueprint.

## Decisions

1. **Hook target — direct `/Applications` path.** `command =
   "/Applications/superwhisper.app/Contents/Resources/claude-hook"`. The cask puts
   `superwhisper.app` at `/Applications`, so the path is stable; it matches the
   reference default. No nix wrapper — a GUI-app-shipped shim can't be `lib.getExe`'d,
   and the existence guard a wrapper would add is moot (hooks only exist where `voice`
   is on, so the binary is present).
2. **Port all five reference hooks.** `Stop`, `Notification`,
   `PreToolUse`(matcher `AskUserQuestion`), `PermissionRequest`, `UserPromptSubmit` —
   the full `hooks/hooks.json` set. All fire the same command; the binary dispatches by
   `hook_event_name`, so including all costs nothing and is a faithful port.
3. **`.claude/settings.local.json` always-allow write — accept, no handling.** It's
   Claude Code's standard per-project local-override file, written at runtime in whatever
   repo you run `claude` in — never into this nix tree by the build. Git-ignoring is a
   per-project concern, orthogonal to this feature. Item closed on the map.

## Merge mechanics (verified)

Upstream `programs.claude-code.settings` (home-manager module,
`modules/programs/claude-code.nix:26-27`) uses `pkgs.formats.json {}` — a **freeform,
recursively-merging** type. So a second definition of `settings.hooks` (from voice.nix)
**merges by key** with the existing block in
`home-modules/settings/programs/claude-code.nix` (which carries `WorktreeCreate` /
`WorktreeRemove`). The SuperWhisper events and the worktree hooks coexist; no clobber.

## Composition / independence (from nix-4t3.2)

- voice.nix contributes the hooks via the darwin `user.*` alias, **unconditionally w.r.t.
  claude-code**, and **never sets `programs.claude-code.enable`**.
- The contribution is inert wherever claude-code is off: the settings.json write is
  gated by `programs.claude-code.enable` (`claude-code.nix:179` gates the value; the
  upstream module writes the file only when enabled).
- Net: **cask → every `voice` Mac; hooks → materialise only on claude-code (firefly)
  Macs** (today: spectre, ash). Honors the map's locked Independent coupling.
- Statusline SuperWhisper indicator is **out of scope here** — designed in nix-4t3.5;
  it will also land in voice.nix at build time.

## Module (blueprint for nix-4t3.6)

```nix
# darwin-modules/features/voice.nix
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.voice;

  # SuperWhisper ships the hook binary inside the cask-installed app bundle.
  # The cask puts superwhisper.app at /Applications, so this path is stable.
  # claude-hook is a shim into the agent-hook binary (nix-4t3.1 /
  # docs/research/superwhisper-claude-hook.md).
  swHook = "/Applications/superwhisper.app/Contents/Resources/claude-hook";
  cmd = { type = "command"; command = swHook; };
in
{
  options.features.voice = {
    enable = mkEnableOption "Voice (SuperWhisper + Claude Code voice hooks)";
  };

  # SuperWhisper is a TCC-gated GUI app (Mic + Accessibility, granted manually),
  # so it comes via Homebrew, not nixpkgs. Cask on every voice Mac.
  #
  # The Claude Code hooks are contributed unconditionally w.r.t. claude-code and
  # never set programs.claude-code.enable: they merge into the freeform
  # settings.hooks (alongside WorktreeCreate/Remove) but are inert wherever
  # claude-code is disabled, since the settings.json write is enable-gated.
  config = mkIf cfg.enable {
    homebrew.casks = [ "superwhisper" ];

    user.programs.claude-code.settings.hooks = {
      Stop = [ { hooks = [ cmd ]; } ];
      Notification = [ { hooks = [ cmd ]; } ];
      PreToolUse = [ { matcher = "AskUserQuestion"; hooks = [ cmd ]; } ];
      PermissionRequest = [ { hooks = [ cmd ]; } ];
      UserPromptSubmit = [ { hooks = [ cmd ]; } ];
    };

    # (nix-4t3.5 adds the SuperWhisper on/off statusline indicator here.)
  };
}
```

### Wiring in `darwin-modules/features/default.nix`

```nix
imports = [
  ./ipfs.nix
  ./k8s.nix
  ./llm.nix
  ./midi-sessions.nix
  ./music.nix
  ./tailscale.nix
  ./voice.nix          # +
];

features = {
  # ...
  voice.enable = machine.features.voice;   # +
};
```

### Host registration (`modules/hosts.nix`) — from nix-4t3.2

- Add `"voice"` to `nebula.features` (structural list).
- Add `"voice"` to each Mac host's `features` list: **spectre**, **ash**.

## Open items handed forward

- **nix-4t3.4** — toggle skill port (writes `/tmp/superwhisper-agent/disabled-<md5($PWD)>`).
- **nix-4t3.5** — statusline SuperWhisper on/off indicator; lands in the `voice.nix`
  config block marked above.
- **nix-4t3.6** — write the module for real, register hosts, build + activate; carry the
  TCC (Mic + Accessibility) manual checklist from the map's Not-yet-specified.
