# Composable Claude Code statusline.
#
# The statusline is a single command Claude Code runs with the session JSON on
# stdin, but its content is contributed by several modules: the base model +
# context segment here, the SuperWhisper indicator from
# darwin-modules/features/voice.nix. Rather than hand-split one script across
# modules, model it as ordered *segments* and generate the script from them.
#
# A segment is a shell body that reads the JSON from `$input` and echoes its
# text (or nothing, to be omitted). Segments render left-to-right by ascending
# `priority`; the generator joins the non-empty parts with " · ".
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
      for p in ${"\${parts[@]+\"\${parts[@]}\"}"}; do
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
        description = ''
          Shell body run for this segment. Reads the Claude Code JSON blob from
          the `$input` environment variable and echoes the segment string, or
          nothing to omit the segment.
        '';
      };
      runtimeInputs = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra packages this segment needs on PATH.";
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
      description = ''
        Assemble the ~/.claude statusline from composable segments and wire it
        into programs.claude-code.settings.statusLine. Defaults on wherever
        claude-code is enabled.
      '';
    };

    segments = mkOption {
      type = types.listOf segmentType;
      default = [ ];
      description = "Statusline segments, joined by ' · ' in ascending priority order.";
    };
  };

  config = mkIf cfg.enable {
    # Base segment: focused session's model + live context-window token usage.
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
