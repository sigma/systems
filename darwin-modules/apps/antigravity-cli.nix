# Darwin module for Google's Antigravity CLI (`agy`) via Homebrew.
#
# The cask drops a single binary at $HOMEBREW_PREFIX/bin/agy, so unlike the
# Antigravity IDE (./antigravity.nix) there is nothing to wrap — the module's
# only other job is pointing the shared agent-skills registry at agy's skill
# directory.
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.antigravity-cli;
in
{
  options.programs.antigravity-cli = {
    enable = mkEnableOption "Antigravity CLI (`agy`, via Homebrew)";
  };

  config = mkIf cfg.enable {
    # agy's global skill directory, added to the shared registry
    # (home-modules/agent-skills.nix) so it holds the same skills as every
    # other agent on the machine.
    #
    # ~/.gemini/config/skills/<skill>/SKILL.md is the global skill location
    # documented at https://antigravity.google/docs/skills/ — the per-project
    # counterpart is <workspace>/.agents/skills, which we deliberately leave
    # alone.
    user.programs.agentSkills.roots = [ ".gemini/config/skills" ];

    homebrew.casks = [ "antigravity-cli" ];
  };
}
