# programs.claude-code.settings → ~/.claude/settings.json
{
  config,
  lib,
  ...
}:
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
  };
}
