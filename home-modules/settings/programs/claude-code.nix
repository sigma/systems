# programs.claude-code.settings → ~/.claude/settings.json
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Statusline script. Claude Code pipes a JSON blob on stdin; the
  # `context_window` object carries live token usage for the focused session
  # (no transcript parsing needed). See
  # https://code.claude.com/docs/en/statusline.md
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      input=$(cat)
      jq -r '
        (.model.display_name // "?")               as $model
        | (.context_window.total_input_tokens // 0)  as $used
        | (.context_window.context_window_size // 200000) as $total
        | (.context_window.used_percentage // 0)     as $pct
        | "\($model) · \(($used / 1000) | floor)k/\(($total / 1000) | floor)k ctx (\($pct | floor)%)"
      ' <<<"$input"
    '';
  };
in
{
  # Gate on enable so hosts without claude-code don't emit a stray settings.json.
  settings = lib.mkIf config.programs.claude-code.enable {
    # Prefer our own curated skillsets (see ./claude-skills.nix) over the CLI's
    # bundled ones; bundled built-ins stay typable as slash commands but are
    # hidden from the model, avoiding name clashes with our skills (e.g.
    # code-review).
    disableBundledSkills = true;

    # Driven from Nix, not claude.ai — turn off the remote-control channel,
    # claude.ai MCP connectors, and the Artifact tool that publishes session
    # output to claude.ai.
    disableRemoteControl = true;
    disableClaudeAiConnectors = true;
    disableArtifact = true;

    # Official LSP plugins for the languages we work in.
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
      "clangd-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
    };

    # Keep extended thinking on by default.
    alwaysThinkingEnabled = true;

    # Don't prompt when entering dangerous (bypass-permissions) mode.
    skipDangerousModePermissionPrompt = true;

    # Show the focused session's model and live context-window token usage.
    statusLine = {
      type = "command";
      command = lib.getExe statusline;
      padding = 0;
    };
  };
}
