# tuicr — code-review TUI (https://github.com/agavra/tuicr).
#
# tuicr itself ships in the toolbox's vcs-toolchain bundle (../content/base.nix).
# This module renders its TOML configuration to ~/.config/tuicr/config.toml and
# registers its agent skills.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.tuicr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.tuicr = {
    enable = mkEnableOption "tuicr configuration";

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "catppuccin-frappe";
          leader = ",";
        }
      '';
      description = ''
        Configuration written verbatim to {file}`~/.config/tuicr/config.toml`.
        See <https://github.com/agavra/tuicr/blob/main/docs/CONFIG.md>.
      '';
    };
  };

  config = lib.mkMerge [
    # Installed everywhere via home.packages, so enable the config everywhere too
    # (matches how hunk is wired).
    {
      programs.tuicr = {
        enable = lib.mkDefault (true);

        settings = {
          # tuicr bundles catppuccin themes directly, so unlike herdr this needs no
          # hex overrides — pick frappe to match the rest of the config.
          theme = "catppuccin-frappe";

          # Single-character leader for panel focus / sidebar / comment shortcuts.
          leader = ",";

          # Review comment taxonomy (Conventional Comments-inspired). `definition`
          # feeds the exported legend that LLMs read; colors are ANSI names (mapped by
          # the frappe theme) except nit, which uses frappe peach. Tweak freely.
          comment_types = [
            {
              id = "issue";
              definition = "a defect or problem that should be fixed";
              color = "red";
            }
            {
              id = "suggestion";
              definition = "a specific, actionable improvement to consider";
              color = "blue";
            }
            {
              id = "question";
              definition = "ask for clarification of intent or behavior";
              color = "yellow";
            }
            {
              id = "nit";
              label = "nitpick";
              definition = "minor, non-blocking style or preference";
              color = "#ef9f76"; # frappe peach
            }
            {
              id = "praise";
              definition = "call out something done well";
              color = "green";
            }
            {
              id = "thought";
              definition = "a non-blocking idea or observation; no action required";
              color = "magenta";
            }
          ];
        };
      };
    }

    (mkIf cfg.enable {
      xdg.configFile."tuicr/config.toml".source = tomlFormat.generate "tuicr-config.toml" cfg.settings;

      # tuicr's agent skills teach agents to drive the review TUI. Under herdr
      # the bundle's herdr wrapper is swapped for one that opens tuicr in a
      # herdr popup, which herdr only exposes to scripts as a plugin pane — so
      # the plugin and the patched skills ship together, from one package
      # (overlays/pkg/local/herdr-tuicr-plugin).
      programs.herdr.plugins = mkIf config.programs.herdr.enable {
        tuicr = pkgs.local.herdr-tuicr-plugin;
      };
      programs.agentSkills.plugins = [
        (
          if config.programs.herdr.enable then
            pkgs.local.herdr-tuicr-plugin.skills
          else
            pkgs.toolbox.tuicr-skills
        )
      ];
    })
  ];
}
