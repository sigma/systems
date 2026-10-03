# programs.agentSkills → skillsets symlinked into every installed agent's skill
# directory (mechanism lives in ../../agent-skills.nix). Tools that ship skills
# of their own (hunk, herdr, tuicr) register them from their modules.
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

  # llm-toolchain merges the toolbox's general skill bundles (Matt Pocock's
  # collection, caveman, ponytail) into one plugin manifest.
  plugins = [ pkgs.toolbox.llm-toolchain ];
}
