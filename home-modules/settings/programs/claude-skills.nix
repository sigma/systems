# programs.claude-skills.plugins → skillsets symlinked into ~/.claude/skills
# (mechanism lives in ../../claude-skills.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Matt Pocock's skill collection, shipped by the toolbox. Add more skillsets
  # by appending plugin packages here.
  plugins = lib.mkIf config.programs.claude-skills.enable [
    pkgs.toolbox.mattpocock-skills
  ];
}
