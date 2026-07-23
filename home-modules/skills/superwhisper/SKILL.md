---
name: superwhisper
description: Toggle SuperWhisper agent integration for this project (on/off/toggle)
args: on|off or empty to toggle
---

Toggle the SuperWhisper Claude Code voice hooks for the *current project*.

SuperWhisper's `agent-hook` binary checks for a per-project disable flag at
`/tmp/superwhisper-agent/disabled-<md5(cwd)>` and no-ops when it is present
(verified in docs/research/superwhisper-claude-hook.md). This skill creates or
removes that exact file, so it gates real hook behavior — the same flag the
statusline SuperWhisper indicator reads.

The hash is md5 of `$PWD` (the session cwd, not the git root) — that is the
convention the binary uses, so it must not be "improved" to anchor on the repo
root.

Run this bash command exactly:

```bash
h=$(printf %s "$PWD" | md5 -q 2>/dev/null || printf %s "$PWD" | md5sum | cut -d' ' -f1); f="/tmp/superwhisper-agent/disabled-$h"; mkdir -p /tmp/superwhisper-agent; case "$ARGUMENTS" in on) rm -f "$f"; echo "SuperWhisper: ON" ;; off) touch "$f"; echo "SuperWhisper: OFF" ;; *) [ -f "$f" ] && { rm -f "$f"; echo "SuperWhisper: ON"; } || { touch "$f"; echo "SuperWhisper: OFF"; } ;; esac
```

Report the single-line output to the user. Nothing else.
