# Design: SuperWhisper statusline indicator via composable segments

Design output for **nix-4t3.5** (map: nix-4t3 — Voice: wire Claude Code to SuperWhisper).
The reference appends a `✓/✗ superwhisper` segment to its statusline. Rather than
hand-splitting this repo's single `claude-statusline` script across modules, model the
statusline as **composable segments**: claude-code.nix registers the base segment, voice.nix
contributes the SuperWhisper segment. The real module is written & activated in **nix-4t3.6**.

## Seam decision

The statusline is one indivisible `writeShellApplication`. Contributions must come from two
modules (claude-code core + voice, darwin-scope). Splitting a monolithic script by hand
duplicates logic; instead introduce a segment abstraction so **voice owns its segment** without
owning the whole script. This revises the nix-4t3.2 note "voice owns the statusline" into:
*the statusline is a shared segmented surface; voice owns its segment.*

Gating: because the SW segment is contributed by voice.nix (a darwin module) under
`mkIf voice.enable`, it is simply **absent** on shirka (linux + firefly, runs claude-code but
no cask) and on any non-voice Mac — the module gate does the gating, no cross-scope nix
reference needed. A lightweight `-x` binary guard remains inside the segment only to avoid a
false `✓` during the first-activation window before Homebrew installs the cask.

## Segment model (decided)

`submodule { priority : int; text : lines; runtimeInputs : listOf package }`

- `priority` — lower = leftmost; segments sorted by it. Robust against module merge order
  (base = 10, SW = 90), so voice appends without knowing the base's position.
- `text` — a shell body that reads the Claude JSON from `$input` and **echoes its segment
  string, or nothing** to be omitted.
- `runtimeInputs` — tools the segment needs (aggregated onto the generator; base needs jq).

Generator joins non-empty parts with ` · ` (matches current style).

## New module — `home-modules/claude-statusline.nix`

Own option namespace `programs.claudeStatusline` (NOT nested under upstream
`programs.claude-code`, which rejects undeclared options).

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.claudeStatusline;

  ordered = sort (a: b: a.priority < b.priority) cfg.segments;

  generator = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ] ++ concatMap (s: s.runtimeInputs) cfg.segments;
    text = ''
      input=$(cat)
      export input
      parts=()
      ${concatMapStringsSep "\n" (s: ''
        part=$(
          ${s.text}
        )
        [ -n "$part" ] && parts+=("$part")
      '') ordered}
      out=""
      for p in ${"$"}{parts[@]+"${"$"}{parts[@]}"}; do
        if [ -z "$out" ]; then out="$p"; else out="$out · $p"; fi
      done
      printf '%s\n' "$out"
    '';
  };

  segmentType = types.submodule {
    options = {
      priority = mkOption {
        type = types.int;
        default = 50;
        description = "Sort key; lower renders further left.";
      };
      text = mkOption {
        type = types.lines;
        description = "Shell body; reads the Claude JSON in $input, echoes the segment or nothing.";
      };
      runtimeInputs = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra tools this segment needs on PATH.";
      };
    };
  };
in
{
  options.programs.claudeStatusline = {
    enable = mkOption {
      type = types.bool;
      default = config.programs.claude-code.enable;
      defaultText = literalExpression "config.programs.claude-code.enable";
      description = "Assemble ~/.claude statusline from composable segments.";
    };
    segments = mkOption {
      type = types.listOf segmentType;
      default = [ ];
      description = "Statusline segments, joined by ' · ' in priority order.";
    };
  };

  config = mkIf cfg.enable {
    # Base segment: model + live context-window usage (moved from claude-code.nix).
    programs.claudeStatusline.segments = [
      {
        priority = 10;
        runtimeInputs = [ pkgs.jq ];
        text = ''
          jq -r '
            (.model.display_name // "?")               as $model
            | (.context_window.total_input_tokens // 0)  as $used
            | (.context_window.context_window_size // 200000) as $total
            | (.context_window.used_percentage // 0)     as $pct
            | "\($model) · \(($used / 1000) | floor)k/\(($total / 1000) | floor)k ctx (\($pct | floor)%)"
          ' <<<"$input"
        '';
      }
    ];

    programs.claude-code.settings.statusLine = mkIf config.programs.claude-code.enable {
      type = "command";
      command = getExe generator;
      padding = 0;
    };
  };
}
```

> Note: `${"$"}{parts[@]+"${"$"}{parts[@]}"}` above is the safe empty-array expansion under
> `set -u` — render it as `"${parts[@]+"${parts[@]}"}"` in the actual `.nix` (escaped here only
> to survive this doc's own `${}` interpolation notation). Nix bash is 5.x, so a plain
> `"${parts[@]}"` is also fine; use whichever reads cleaner at build time.

### `claude-code.nix` change

Remove the `statusline = pkgs.writeShellApplication { ... }` let-binding and the
`statusLine = { ... }` entry from the `settings` block — both move into the base segment above.
(The base segment could equally be registered from claude-code.nix rather than the new module;
kept in the new module here so all statusline logic lives in one place. Either honors "segments
from claude-code.nix" — the model/ctx content is unchanged, just relocated.)

### `voice.nix` addition (under `mkIf cfg.enable`, from nix-4t3.3/4)

```nix
user.programs.claudeStatusline.segments = [
  {
    priority = 90;
    text = ''
      # Only meaningful once the cask is installed (avoids a false ✓ during the
      # first activation before Homebrew places superwhisper.app).
      if [ -x /Applications/superwhisper.app/Contents/Resources/claude-hook ]; then
        dir=$(jq -r '.workspace.current_dir // empty' <<<"$input")
        h=$(printf %s "$dir" | md5 -q 2>/dev/null || printf %s "$dir" | md5sum | cut -d' ' -f1)
        if [ -f "/tmp/superwhisper-agent/disabled-$h" ]; then
          echo "✗ superwhisper"
        else
          echo "✓ superwhisper"
        fi
      fi
    '';
  }
];
```

Hashes `.workspace.current_dir` (the session cwd) — the exact directory the hook binary and the
`/superwhisper` skill (nix-4t3.4) hash — so the indicator tracks the real disable flag
`/tmp/superwhisper-agent/disabled-<md5(cwd)>`.

## Handed forward to nix-4t3.6

- Create `home-modules/claude-statusline.nix`; import it (home-modules/default.nix).
- Relocate the base segment out of `claude-code.nix`.
- Add the SW segment block to `voice.nix`.
- Verify parity: standalone home-manager vs system produce the same statusline command.
