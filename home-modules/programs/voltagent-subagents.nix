# VoltAgent's Claude Code subagent catalog (toolbox `voltagent-subagents`).
#
# The package enables no agent. Global agents are picked by name below and
# linked into ~/.claude/agents/; others are enabled per project through the
# bundled `subagent-catalog` skill, which copies a definition into the
# project's .claude/agents/.
#
# home.file rather than programs.claude-code.agents: that option writes a
# string value as the file's *text*, and reading a store path at eval time is
# IFD. A misspelt name fails the build: its `source` does not exist.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.voltagent-subagents;
  subagents = pkgs.toolbox.voltagent-subagents;
in
{
  options.programs.voltagent-subagents = {
    enable = mkEnableOption "VoltAgent subagents for Claude Code";

    agents = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "code-reviewer" ];
      description = ''
        Agent names to enable globally, linked into
        {file}`~/.claude/agents/`. Names: `subagent-catalog list`, or the
        package's `catalog.json`.
      '';
    };
  };

  config = mkMerge [
    { programs.voltagent-subagents.enable = mkDefault config.programs.claude-code.enable; }

    (mkIf cfg.enable {
      programs.voltagent-subagents.agents = [
        "architect-reviewer"
        "backend-developer"
        "build-engineer"
        "code-reviewer"
        "debugger"
        "devops-engineer"
        "fullstack-developer"
        "golang-pro"
        "kubernetes-specialist"
        "microservices-architect"
        "platform-engineer"
        "refactoring-specialist"
        "rust-engineer"
        "security-auditor"
        "tooling-engineer"
        "typescript-pro"
      ];

      # The plugin manifest lists only the subagent-catalog skill, never agents.
      # A Claude plugin, not programs.agentSkills: the skill writes
      # .claude/agents/, which no other agent reads.
      programs.claude-code.plugins = [ subagents ];

      home.file = listToAttrs (
        map (name: {
          name = "${config.programs.claude-code.configDir}/agents/${name}.md";
          value.source = "${subagents}/agents/${name}.md";
        }) cfg.agents
      );
    })
  ];
}
