# Composable Claude Code statusline.
#
# The statusline is a single command Claude Code runs with the session JSON on
# stdin, but its content comes from two places: a *base renderer* — the packaged
# kcchien/claude-code-statusline script, which draws the model, context gradient
# bar, cost, duration, rate limits, git branch and worktree — and a list of
# *segments* contributed by other modules (e.g. the SuperWhisper indicator from
# darwin-modules/features/voice.nix).
#
# The base renderer is monolithic and emits two lines, so segments cannot be
# interleaved into it. Instead the generator appends them as a third line,
# joined with " · " in ascending `priority` order. A segment is a shell body
# that reads the JSON from `$input` and echoes its text (or nothing, to be
# omitted).
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

  # Nerd Font glyphs are only legible if the terminal is actually rendering a
  # Nerd Font, so key this off the resolved terminal font profile rather than
  # hardcoding it. Fonts are only installed on graphical hosts (see
  # home-modules/fonts/default.nix), so a headless devbox correctly opts out
  # even though its profile may still name one.
  profiles = config.programs.fontProfiles;
  terminalFamilies =
    if profiles ? terminal then
      [ profiles.terminal.family.family ]
      ++ map (f: if isString f then f else f.family) profiles.terminal.fallbacks
    else
      [ ];
  nerdFontDetected =
    config.features.graphical.enable && any (f: hasInfix "Nerd Font" f) terminalFamilies;

  generator = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ] ++ concatMap (s: s.runtimeInputs) cfg.segments;
    text = ''
      input=$(cat)
      export input

      # The renderer opts into glyphs/separators purely through the
      # environment; it is otherwise unconfigured.
      export CLAUDE_STATUSLINE_NERDFONT=${if cfg.nerdfont then "1" else "0"}

      # A renderer failure degrades to segments-only rather than an empty
      # statusline, so a broken base never hides the other indicators.
      base=$(printf '%s' "$input" | ${getExe cfg.package}) || base=""

      parts=()
      ${concatMapStringsSep "\n" (s: ''
        part=$(
          ${s.text}
        )
        [ -n "$part" ] && parts+=("$part")
      '') ordered}
      extra=""
      for p in ${"\${parts[@]+\"\${parts[@]}\"}"}; do
        if [ -z "$extra" ]; then extra="$p"; else extra="$extra · $p"; fi
      done

      printf '%s' "$base"
      if [ -n "$extra" ]; then
        if [ -n "$base" ]; then printf '\n'; fi
        printf '%s' "$extra"
      fi
      printf '\n'
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
        Assemble the ~/.claude statusline from a base renderer plus composable
        segments, and wire it into programs.claude-code.settings.statusLine.
        Defaults on wherever claude-code is enabled.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.local.claude-code-statusline;
      defaultText = literalExpression "pkgs.local.claude-code-statusline";
      description = ''
        Base renderer: a program reading the Claude Code session JSON on stdin
        and writing the leading statusline lines to stdout.
      '';
    };

    nerdfont = mkOption {
      type = types.bool;
      default = nerdFontDetected;
      defaultText = literalExpression ''
        the terminal font profile resolves to a Nerd Font on a graphical host
      '';
      description = ''
        Render the base statusline with Nerd Font glyphs and Powerline
        separators. Defaults to whether the configured terminal font profile
        actually provides a Nerd Font, so hosts without one keep the Unicode
        fallback instead of showing tofu.
      '';
    };

    segments = mkOption {
      type = types.listOf segmentType;
      default = [ ];
      description = ''
        Extra statusline segments, appended below the base renderer's output
        and joined by ' · ' in ascending priority order.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code.settings.statusLine = mkIf config.programs.claude-code.enable {
      type = "command";
      command = getExe generator;
      padding = 0;
    };
  };
}
