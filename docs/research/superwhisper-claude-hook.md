# SuperWhisper claude-hook: binary & interface

Research for **nix-4t3.1** (map: nix-4t3 — Voice: wire Claude Code to SuperWhisper).
Findings verified against the locally-installed app **v2.16.5** and the reference
repo `github.com/superultrainc/superwhisper-claude-code` (cloned to `/tmp/sw-ref`).

## TL;DR

- The reference's hardcoded path is real: `/Applications/superwhisper.app/Contents/Resources/claude-hook`.
- The Homebrew cask `superwhisper` installs `superwhisper.app` as an App artifact →
  default `/Applications/superwhisper.app`, so the path holds under the `voice` cask.
- `claude-hook` is a 56-byte shell shim; the real logic is the `agent-hook` Mach-O binary.
- The per-project disable file **actually gates behavior in the binary** (not display-only).
  The `SUPERWHISPER_AGENT=0` env var does **not** — it is display-only in the statusline.
- Version installed (2.16.5) and cask (2.16.6) both satisfy the README's 2.13+ minimum.

## Path & install

- Cask: `brew info --cask superwhisper` → v2.16.6, `auto_updates`, requires macOS ≥ 14.
  Artifact: `superwhisper.app (App)` → installs to `/Applications/superwhisper.app`.
- Hook entry point: `/Applications/superwhisper.app/Contents/Resources/claude-hook`.
- `claude-hook` contents (verbatim):
  ```sh
  #!/bin/sh
  exec "$(dirname "$0")/agent-hook" claude "$@"
  ```
  So it dispatches to the sibling `agent-hook` binary with subcommand `claude`.
  `${CLAUDE_HOOK:-...}` in the reference's `hooks.json` lets an env var override the path,
  but the default is the hardcoded `/Applications` path.
- **Caveat — auto-updating app:** the cask has `auto_updates true`; SuperWhisper self-updates
  in place. The bundle path is stable, but the version drifts out from under Nix. Acceptable
  for a GUI app (consistent with other TCC-gated casks), just not version-pinned.

## What it reads from stdin

Standard Claude Code hook JSON. Binary strings reference:
`hook_event_name`, `session_id`, `transcript_path`, `stop_hook_active`,
`notification_type`, `permission_mode`, `permission_suggestions`, `cwd`.

## What events it handles

The single binary is a multi-event dispatcher (falls back to Stop for unknown events —
`Unknown event, defaulting to Stop handler`). The reference `hooks.json` wires it to **five**
hook points, all pointing at the same command:

| Hook | Matcher | Purpose |
|------|---------|---------|
| `Stop` | — | Agent finished → notify SuperWhisper with the final message (voice reply loop). |
| `Notification` | — | Attention/permission notifications surfaced to SuperWhisper. |
| `PreToolUse` | `AskUserQuestion` | Question flow; can pre-answer/auto-approve. |
| `PermissionRequest` | — | Permission prompts relayed to SuperWhisper. |
| `UserPromptSubmit` | — | Track prompt submission. |

Behavior: on Stop it fires a `superwhisper://` deeplink notification
(`Notification sent: agent=… status=… summary=…`; README example
`superwhisper://agent-update?agent=…&status=completed&summary=…`). The scheme is
selectable via `SUPERWHISPER_SCHEME` / bundle id `com.superduper.superwhisper`
(`…superwhisper.debug` for the debug build).

**Side effect worth noting for declarative config:** the binary writes an
`always-allow` ruleset into the project's `.claude/settings.local.json`
(strings: `Always-allow: wrote rules to …`, `Always-allow: persisted …`). It mutates
per-project `.claude/settings.local.json` in the cwd — not our managed global settings,
but a source of untracked local files. Not a blocker; flag for nix-4t3.3.

## Per-project / session gating (this decides the toggle skill)

**Confirmed: the binary itself honors the disable file.** Binary strings:
`/tmp/superwhisper-agent`, `/disabled-`, and crucially:
```
Exiting: superwhisper disabled for cwd=
Exiting: superwhisper disabled for session=
```
So a present `/tmp/superwhisper-agent/disabled-<md5(cwd)>` file makes the hook a no-op —
real behavioral gating, not cosmetic. There is also a session-scoped disable path.

- **Disable file:** `/tmp/superwhisper-agent/disabled-<hash>` where
  `<hash> = md5( $PWD )` — i.e. `echo -n "$PWD" | md5 -q` (fallback `md5sum | cut -d' ' -f1`).
  Hash is over the **current working directory**, not the git root.
- **`SUPERWHISPER_AGENT=0`:** referenced **only** in the reference `statusline.sh`, **not** in
  `agent-hook`. It flips the statusline glyph but does **not** disable the hook. Treat it as
  display-only; the toggle skill must use the `/tmp` file to actually gate behavior.

Reference toggle skill (`skills/superwhisper/SKILL.md`) does exactly this — touch/rm the
`/tmp/superwhisper-agent/disabled-<md5(pwd)>` file (on = rm, off = touch, no-arg = toggle).
→ Port target for **nix-4t3.4** is sound; it gates real behavior.

Reference statusline (`config/statusline.sh`) shows `✓/✗ superwhisper` by checking the same
`/tmp` file **or** `SUPERWHISPER_AGENT=0`. → Input for **nix-4t3.5**.

## TCC / permission prerequisites

- These are the **app's** permissions, granted manually via System Settings (TCC), not
  configurable in Nix — aligns with the repo memory that TCC-gated tools go via Homebrew.
- **Microphone** — required for dictation (the point of the app).
- **Accessibility** — required for SuperWhisper to surface over other windows (README: "opens
  over any other windows"), and for injecting the voice response.
- The `agent-hook` binary itself only reads stdin, touches `/tmp`, reads the Claude transcript,
  and fires `open superwhisper://…` deeplinks — no extra TCC grant for the hook itself.
- → Feeds the map's "Not yet specified" TCC note; likely a manual checklist in nix-4t3.6, not config.

## Version

- Installed app: `CFBundleShortVersionString = 2.16.5`. Cask: 2.16.6. README minimum: 2.13.
  ✓ satisfied.

## Answers to the ticket's explicit questions

1. **Path / cask location** — `/Applications/superwhisper.app/Contents/Resources/claude-hook`;
   cask installs the `.app` to `/Applications`. ✓
2. **stdin / what it does** — reads Claude Code hook JSON; on Stop/Notification/permission
   events fires a `superwhisper://agent-update` deeplink; also persists an always-allow ruleset
   to per-project `.claude/settings.local.json`.
3. **Min version** — 2.13+; installed 2.16.5 satisfies it.
4. **Disable flag / env** — the `/tmp/superwhisper-agent/disabled-<md5(cwd)>` file gates the
   **binary** (real). `SUPERWHISPER_AGENT=0` is **display-only** (statusline). The toggle skill
   must write the file, not the env var.
5. **TCC** — Microphone + Accessibility, granted manually to the app; not hook-level.
