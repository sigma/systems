{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  tomlFormat = pkgs.formats.toml {};

  cfg = config.programs.jujutsu;
  scopeModule = types.submodule {
    options = {
      repositories = mkOption {
        type = types.listOf types.str;
        default = [];
      };

      commands = mkOption {
        type = types.listOf types.str;
        default = [];
      };

      settings = mkOption {
        type = types.attrs;
        default = {};
      };
    };
  };
in {
  options.programs.jujutsu = {
    enableUI = mkOption {
      type = types.bool;
      default = true;
    };

    enableMergiraf = mkOption {
      type = types.bool;
      default = true;
    };

    scopes = mkOption {
      type = types.attrsOf scopeModule;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      [
        pkgs.jujutsu
      ]
      ++ lib.optionals cfg.enableUI [
        pkgs.jjui
      ]
      ++ lib.optionals cfg.enableMergiraf [
        pkgs.mergiraf
      ];

    xdg.configFile = lib.mkMerge (
      map
      (
        scopeName: let
          scope = cfg.scopes.${scopeName};
          content =
            scope.settings
            // lib.optionalAttrs (scope.repositories != []) {
              "--when".repositories = scope.repositories;
            }
            // lib.optionalAttrs (scope.commands != []) {
              "--when".commands = scope.commands;
            };
        in {
          "jj/conf.d/${scopeName}.toml".source = tomlFormat.generate "${scopeName}.toml" content;
        }
      )
      (builtins.attrNames cfg.scopes)
    );
  };
}
