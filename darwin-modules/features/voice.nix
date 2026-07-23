{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.features.voice;

  # SuperWhisper ships the hook binary inside the cask-installed app bundle.
  # The cask (homebrew.casks below) puts superwhisper.app at /Applications, so
  # this path is stable. `claude-hook` is a shim into the `agent-hook` binary
  # that dispatches on the hook JSON's hook_event_name (verified in
  # docs/research/superwhisper-claude-hook.md).
  swHook = "/Applications/superwhisper.app/Contents/Resources/claude-hook";
  cmd = {
    type = "command";
    command = swHook;
  };
in
{
  options.features.voice = {
    enable = mkEnableOption "Voice (SuperWhisper cask)";

    claudeCode.enable = mkEnableOption
      "the SuperWhisper integration into Claude Code (voice hooks, /superwhisper toggle skill, statusline indicator)";
  };

  # SuperWhisper is a TCC-gated GUI app (Microphone + Accessibility, granted
  # manually in System Settings), so it comes via Homebrew, not nixpkgs. The
  # cask installs on every voice Mac (below, under cfg.enable).
  #
  # The Claude Code integration (hooks + /superwhisper skill + statusline
  # segment) is a separate opt-in: `features.voice.claudeCode.enable`, off by
  # default. It never sets programs.claude-code.enable — it only merges into
  # the freeform settings.hooks (alongside WorktreeCreate/Remove), the skills
  # dir, and the statusline segments, so it also stays inert wherever
  # claude-code itself is disabled (the settings.json write and skill discovery
  # are enable-gated).
  config = mkIf cfg.enable {
    homebrew.casks = [ "superwhisper" ];

    user = mkIf cfg.claudeCode.enable {
      # Attention (Notification / PermissionRequest / AskUserQuestion) +
      # completion (Stop) + prompt tracking (UserPromptSubmit) — the reference
      # set. All fire the same command; the binary dispatches by event.
      programs.claude-code.settings.hooks = {
        Stop = [ { hooks = [ cmd ]; } ];
        Notification = [ { hooks = [ cmd ]; } ];
        PreToolUse = [
          {
            matcher = "AskUserQuestion";
            hooks = [ cmd ];
          }
        ];
        PermissionRequest = [ { hooks = [ cmd ]; } ];
        UserPromptSubmit = [ { hooks = [ cmd ]; } ];
      };

      # Per-project toggle skill (/superwhisper on|off). Writes the same disable
      # flag the binary honors; see the skill file for the convention.
      home.file.".claude/skills/superwhisper/SKILL.md".source =
        ../../home-modules/skills/superwhisper/SKILL.md;

      # Statusline SuperWhisper on/off indicator. Reads the same per-project
      # disable flag (/tmp/superwhisper-agent/disabled-<md5(cwd)>), hashing the
      # session dir the hook binary and skill hash (.workspace.current_dir), so
      # the glyph tracks real gating. The `-x` guard avoids a false ✓ during the
      # first activation before Homebrew installs the cask.
      programs.claudeStatusline.segments = [
        {
          priority = 90;
          text = ''
            if [ -x ${swHook} ]; then
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
    };
  };
}
