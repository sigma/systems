# Packaged Claude Code skillsets → ~/.claude/skills.
#
# Each skillset is a Claude Code *plugin* package: a `.claude-plugin/plugin.json`
# manifest plus a `skills/` tree. The toolbox ships them (e.g. Matt Pocock's
# collection); add more by appending packages to `programs.claude-skills.plugins`.
#
# Why not `programs.claude-code.skills`? That upstream option only symlinks a
# genuine Nix `path`, and pointing a path at a *package output* fails under
# pure/flake eval (see the long note in ./hunk.nix). So we take the same escape
# hatch hunk uses: a `"${package}/…"` *string* as a `home.file` source.
#
# Claude Code discovers a personal skill at ~/.claude/skills/<name>/SKILL.md
# (one level deep), but plugins nest them under skills/<category>/<name>. We
# read each plugin's manifest (IFD, allowed repo-wide — see modules/nix.nix) to
# learn every skill's path and symlink its leaf directory flat. Driving this off
# the manifest means the set tracks upstream automatically on input bumps.
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.claude-skills;

  # plugin.json "skills" entries are package-relative paths like
  # "./skills/engineering/tdd"; the leaf name is the skill id Claude Code uses.
  skillsFrom =
    plugin:
    let
      manifest = builtins.fromJSON (builtins.readFile "${plugin}/.claude-plugin/plugin.json");
    in
    map (rel: {
      name = baseNameOf rel;
      source = "${plugin}/${removePrefix "./" rel}";
    }) manifest.skills;

  allSkills = filter (e: !(elem e.name cfg.exclude)) (concatMap skillsFrom cfg.plugins);
in
{
  options.programs.claude-skills = {
    enable = mkOption {
      type = types.bool;
      default = config.programs.claude-code.enable;
      defaultText = literalExpression "config.programs.claude-code.enable";
      description = ''
        Symlink packaged Claude Code skillsets into ~/.claude/skills so Claude
        Code discovers them. Defaults on wherever claude-code is enabled.
      '';
    };

    plugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.toolbox.mattpocock-skills ]";
      description = ''
        Claude Code plugin packages to install skills from. Each must contain a
        `.claude-plugin/plugin.json` manifest and the `skills/` tree it lists.
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

  config = mkIf cfg.enable {
    home.file = listToAttrs (
      map (e: nameValuePair ".claude/skills/${e.name}" { source = e.source; }) allSkills
    );
  };
}
