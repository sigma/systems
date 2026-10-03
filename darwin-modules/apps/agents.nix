# Darwin delivery for the agent roster (home-modules/agents.nix).
#
# Installs each installed agent's Homebrew formula or cask. claude-code gets a
# wrapper package delegating to the cask's binary, so the home-manager
# claude-code module (settings, skills, hooks) drives the Homebrew install.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  agents = attrValues (filterAttrs (_: a: a.installed) config.user.programs.agents);
in
{
  homebrew.brews = concatMap (a: optional (a.darwin.brew != null) a.darwin.brew) agents;
  homebrew.casks = concatMap (a: optional (a.darwin.cask != null) a.darwin.cask) agents;

  user.programs.claude-code.package = pkgs.writeShellScriptBin "claude" ''
    exec ${config.homebrew.prefix}/bin/claude "$@"
  '';
}
