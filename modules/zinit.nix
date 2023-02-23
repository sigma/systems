{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.zsh.zinit;

  pluginModule = types.submodule ({config, ...}: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      light = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable light-mode";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The plugin tags.";
      };

      pre = mkOption {
        type = types.str;
        default = "";
        description = "The plugin pre-config";
      };
    };
  });
in {
  options.programs.zsh.zinit = {
    enable = mkEnableOption "zinit - a zsh plugin manager";

    plugins = mkOption {
      default = [];
      type = types.listOf pluginModule;
      description = "List of zinit plugins.";
    };

    pre = mkOption {
      type = types.str;
      default = "";
      description = "pre-zinit config";
    };

    post = mkOption {
      type = types.str;
      default = "";
      description = "post-zinit config";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.zinit];

    programs.zsh.initExtraBeforeCompInit = ''
      source ${pkgs.zinit}/share/zinit/zinit.zsh

      ${
        optionalString (cfg.pre != "") ''
          ${cfg.pre}
        ''
      }
      ${optionalString (cfg.plugins != []) ''
        ${concatStrings (map (plugin: ''
            ${
              optionalString (plugin.pre != "") ''
                ${plugin.pre}
              ''
            }
            ${
              optionalString (plugin.tags != []) ''
                zinit ice ${concatStrings (map (tag: " ${tag}") plugin.tags)}
              ''
            }
            zinit ${
              if plugin.light
              then "light"
              else "load"
            } "${plugin.name}"
          '')
          cfg.plugins)}
      ''}
      ${
        optionalString (cfg.post != "") ''
          ${cfg.post}
        ''
      }
    '';
  };
}
