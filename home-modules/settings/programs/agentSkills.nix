# programs.agentSkills → skillsets symlinked into every installed agent's skill
# directory (mechanism lives in ../../agent-skills.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Claude Code's own skill directory. Agents installed by a darwin/nixos module
  # add theirs from there (e.g. darwin-modules/apps/antigravity-cli.nix).
  roots = lib.optional config.programs.claude-code.enable ".claude/skills";

  # Matt Pocock's skill collection, shipped by the toolbox. Add more skillsets
  # by appending plugin packages here. Skipped entirely when no agent is
  # installed — reading the manifests is IFD, so it is not free.
  plugins = lib.mkIf (config.programs.agentSkills.roots != [ ]) (
    [
      pkgs.toolbox.mattpocock-skills
    ]
    # tuicr's own skills teach agents to drive the review TUI, so they are only
    # worth shipping where tuicr itself is configured (see ../../tuicr.nix).
    ++ lib.optional config.programs.tuicr.enable pkgs.toolbox.tuicr-skills
  );
}
