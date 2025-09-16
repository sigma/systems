{
  pkgs,
  lib,
  ...
}:
with lib;
let
  jsonFormat = pkgs.formats.json { };
  keybindingType = types.listOf (
    types.submodule {
      options = {
        key = mkOption {
          type = types.str;
        };

        command = mkOption {
          type = types.str;
        };

        when = mkOption {
          type = types.nullOr (types.str);
          default = null;
        };

        args = mkOption {
          type = types.nullOr (jsonFormat.type);
          default = null;
        };
      };
    }
  );
in
{
  options = {
    userSettings = mkOption {
      type = jsonFormat.type;
      default = { };
    };

    userTasks = mkOption {
      type = jsonFormat.type;
      default = { };
    };

    keybindings = mkOption {
      type = keybindingType;
      default = [ ];
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    languageSnippets = mkOption {
      type = jsonFormat.type;
      default = { };
    };

    globalSnippets = mkOption {
      type = jsonFormat.type;
      default = { };
    };
  };
}
