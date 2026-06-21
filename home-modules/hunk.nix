{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.hunk;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.hunk = {
    enable = mkEnableOption "hunk (review-first terminal diff viewer)";

    package = mkOption {
      type = types.package;
      default = pkgs.toolbox.hunk;
      defaultText = literalExpression "pkgs.toolbox.hunk";
      description = "The hunk package to install.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Free-form config written verbatim to ~/.config/hunk/config.toml.
        See https://github.com/modem-dev/hunk for valid keys. Omit
        `vcs` to let hunk auto-detect the surrounding checkout.
      '';
      example = literalExpression ''
        {
          theme = "github-dark-default";
          mode = "auto";
          line_numbers = true;
        }
      '';
    };

    git.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      defaultText = literalExpression "config.programs.hunk.enable";
      description = ''
        Wire hunk in as git's pager (`core.pager = "hunk pager"`) and
        turn off the home-manager delta/git integration so the two
        don't collide on `core.pager`. Delta itself stays available
        via `pkgs.delta` for any tool that references it directly.
      '';
    };

    jj.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      defaultText = literalExpression "config.programs.hunk.enable";
      description = ''
        Wire hunk in as jj's pager (`ui.pager = ["hunk" "pager"]`) and
        set `ui.diff-formatter = ":git"` so hunk receives input it can
        parse.
      '';
    };

    claudeSkill.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      defaultText = literalExpression "config.programs.hunk.enable";
      description = ''
        Symlink the hunk-shipped SKILL.md into
        ~/.claude/skills/hunk-review so Claude Code picks it up.
        Directory name matches the upstream skill id (the path
        `hunk skill path` prints).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      # Baseline written to ~/.config/hunk/config.toml. These match
      # hunk's own internal defaults but having them in the file
      # makes the resolved config visible and overridable in one
      # place. User-set programs.hunk.settings.* wins (mkDefault).
      programs.hunk.settings = {
        mode = mkDefault "auto";
        line_numbers = mkDefault true;
        wrap_lines = mkDefault false;
        hunk_headers = mkDefault true;
      };

      xdg.configFile."hunk/config.toml".source =
        tomlFormat.generate "hunk-config.toml" cfg.settings;
    }

    (mkIf cfg.git.enable {
      programs.git.settings.core.pager = "${cfg.package}/bin/hunk pager";
      # HM's delta module auto-sets core.pager when enabled; disable
      # its wiring so we don't double-define. `pkgs.delta` is still
      # in scope for direct references (lazygit, gh, jj's `delta`
      # scope all use ${pkgs.delta} rather than programs.delta).
      programs.delta.enable = mkForce false;
    })

    (mkIf cfg.jj.enable {
      programs.jujutsu.settings.ui = {
        pager = mkForce [
          "${cfg.package}/bin/hunk"
          "pager"
        ];
        diff-formatter = mkForce ":git";
      };
    })

    (mkIf cfg.claudeSkill.enable {
      programs.claude-code.skills.hunk-review = "${cfg.package}/skills/hunk-review";
    })

    # Catppuccin integration: when catppuccin is globally enabled,
    # default the theme to the matching catppuccin-<flavor> variant.
    # User-provided settings.theme overrides this (it's `mkDefault`).
    (mkIf config.catppuccin.enable {
      programs.hunk.settings.theme = mkDefault "catppuccin-${config.catppuccin.flavor}";
    })
  ]);
}
