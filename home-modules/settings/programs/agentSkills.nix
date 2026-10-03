# programs.agentSkills → skillsets symlinked into every installed agent's skill
# directory (mechanism lives in ../../agent-skills.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Every installed roster agent's skill directory (see ../../agents.nix).
  roots = lib.pipe config.programs.agents [
    (lib.filterAttrs (_: a: a.installed && a.skillDir != null))
    (lib.mapAttrsToList (_: a: a.skillDir))
  ];

  # Skill bundles shipped by the toolbox. Skipped entirely when no agent is
  # installed — reading the manifests is IFD, so it is not free.
  plugins = lib.mkIf (config.programs.agentSkills.roots != [ ]) (
    # llm-toolchain merges its skill bundles (Matt Pocock's collection,
    # caveman, ponytail) into one plugin manifest.
    [ pkgs.toolbox.llm-toolchain ]
    # tuicr's own skills teach agents to drive the review TUI, so they are only
    # worth shipping where tuicr itself is configured (see ../../tuicr.nix).
    # Under herdr the bundle's herdr wrapper is swapped for one that opens
    # tuicr in a popup, provided by the herdr plugin linked in ./herdr.nix.
    ++ lib.optional config.programs.tuicr.enable (
      if config.programs.herdr.enable then
        pkgs.local.herdr-tuicr-plugin.skills
      else
        pkgs.toolbox.tuicr-skills
    )
    # Likewise herdr's: they teach agents to drive the multiplexer's panes and
    # sessions, which is only useful where herdr is configured (see
    # ../../herdr.nix).
    ++ lib.optional config.programs.herdr.enable pkgs.toolbox.herdr-skills
  );
}
