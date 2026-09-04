# Agent skills, shared across every coding agent installed on the machine.
#
# A *skill* is a directory holding a SKILL.md (plus optional scripts/, examples/,
# resources/). Claude Code and Antigravity both read that same layout, they just
# scan different directories — so this module keeps one registry and links it
# into all of them:
#
#   skills  : skill id → the directory holding its SKILL.md
#   roots   : home-relative directories to link that whole set into, one per
#             agent (~/.claude/skills, ~/.gemini/config/skills, …)
#
# Modules that *ship* a skill register it in `skills` (hunk, superwhisper);
# modules that *install an agent* add its directory to `roots`. Nothing here
# knows which agent is which, which is what makes the installed skill set
# identical across all of them. Where each root comes from is decided in
# ./settings/programs/agentSkills.nix and in the per-agent modules.
#
# `plugins` is a bulk source for `skills`: a Claude Code *plugin* package, i.e.
# a `.claude-plugin/plugin.json` manifest plus the `skills/` tree it lists. The
# toolbox ships them (e.g. Matt Pocock's collection). That packaging format is
# Claude's, but the skills inside it are not — they work in any agent.
#
# Why home.file rather than `programs.claude-code.skills`? That upstream option
# only symlinks a genuine Nix `path`, and pointing a path at a *package output*
# fails under pure/flake eval (see the long note in ./hunk.nix). So we take the
# same escape hatch hunk uses: a `"${package}/…"` *string* as a `home.file`
# source.
#
# Agents discover a skill one level deep (<root>/<id>/SKILL.md), but plugins
# nest them under skills/<category>/<id>. We read each plugin's manifest (IFD,
# allowed repo-wide — see modules/nix.nix) to learn every skill's path and
# symlink its leaf directory flat. Driving this off the manifest means the set
# tracks upstream automatically on input bumps.
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.agentSkills;

  # plugin.json "skills" entries are package-relative paths like
  # "./skills/engineering/tdd"; the leaf name is the skill id agents use.
  skillsFrom =
    plugin:
    let
      manifest = builtins.fromJSON (builtins.readFile "${plugin}/.claude-plugin/plugin.json");
    in
    map (rel: nameValuePair (baseNameOf rel) "${plugin}/${removePrefix "./" rel}") manifest.skills;

  wanted = filterAttrs (name: _: !(elem name cfg.exclude)) cfg.skills;

  # One symlink per (root, skill): the same leaf directory under every agent's
  # skill root, so every agent sees the same set.
  linksUnder =
    root: mapAttrs' (name: source: nameValuePair "${root}/${name}" { inherit source; }) wanted;
in
{
  options.programs.agentSkills = {
    skills = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ hunk-review = "''${pkgs.hunk}/skills/hunk-review"; }'';
      description = ''
        Skill id → directory containing that skill's `SKILL.md`. Populated from
        {option}`plugins`, and by any module shipping a skill of its own; every
        entry is linked into each of {option}`roots`.
      '';
    };

    roots = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        ".claude/skills"
        ".gemini/config/skills"
      ];
      description = ''
        Home-relative directories to link every skill into — one per agent that
        reads its own skill root. Modules installing such an agent append theirs.
        With no roots, nothing is linked and no agent is on the machine to care.
      '';
    };

    plugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.toolbox.mattpocock-skills ]";
      description = ''
        Claude Code plugin packages to install skills from. Each must contain a
        `.claude-plugin/plugin.json` manifest and the `skills/` tree it lists.
        Their skills are merged into {option}`skills`.
      '';
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "code-review" ];
      description = ''
        Skill ids (leaf directory names) to leave out — across all plugins.
      '';
    };
  };

  config = {
    programs.agentSkills.skills = listToAttrs (concatMap skillsFrom cfg.plugins);

    home.file = mkMerge (map linksUnder cfg.roots);
  };
}
