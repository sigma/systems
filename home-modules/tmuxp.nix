{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.tmux.tmuxp;

  cplxCmd = types.submodule (
    { ... }:
    {
      options = {
        cmd = mkOption {
          type = types.str;
          description = "The command";
        };

        enter = mkOption {
          type = types.nullOr (types.bool);
          default = null;
          description = "Whether to run the command";
        };

        sleep_before = mkOption {
          type = types.nullOr (types.ints.unsigned);
          default = null;
          description = "How long to sleep before the command";
        };

        sleep_after = mkOption {
          type = types.nullOr (types.ints.unsigned);
          default = null;
          description = "How long to sleep after the command";
        };
      };
    }
  );
  singleCmd = types.either types.str cplxCmd;
  cmd = types.either singleCmd (types.listOf singleCmd);
  emptyPane = types.nullOr (
    types.enum [
      "blank"
      "pane"
    ]
  );
  pane = types.submodule (
    { ... }:
    {
      options = {
        focus = mkOption {
          type = types.nullOr (types.bool);
          default = null;
          description = "Whether to focus this pane";
        };

        shell = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The shell to interpret shell_command";
        };

        shell_command = mkOption {
          type = types.nullOr cmd;
          default = null;
          description = "Command to run";
        };

        environment = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Environment";
        };

        start_directory = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The base directory";
        };
      };
    }
  );
  window = types.submodule (
    { ... }:
    {
      options = {
        window_name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The name of the window";
        };

        window_index = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          description = "The window index";
        };

        panes = mkOption {
          type = types.listOf (
            types.oneOf [
              emptyPane
              pane
              singleCmd
            ]
          );
          default = [ ];
          description = "List of panes";
        };

        shell_command_before = mkOption {
          type = types.nullOr cmd;
          default = null;
          description = "Command to run before";
        };

        layout = mkOption {
          type = types.nullOr (
            types.enum [
              "even-horizontal"
              "even-vertical"
              "main-horizontal"
              "main-vertical"
              "tiled"
            ]
          );
          default = null;
          description = "Layout";
        };

        options = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Options";
        };

        options_after = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Options after panes creation";
        };

        environment = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Environment";
        };
      };
    }
  );
  workspace = types.submodule (
    { ... }:
    {
      options = {
        session_name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The name of the session";
        };

        start_directory = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The base directory";
        };

        windows = mkOption {
          type = types.listOf window;
          default = [ ];
          description = "List of windows";
        };

        shell_command_before = mkOption {
          type = types.nullOr cmd;
          default = null;
          description = "Command to run before";
        };

        before_script = mkOption {
          type = types.nullOr cmd;
          default = null;
          description = "Command to run before";
        };

        global_options = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Global tmux options";
        };

        options = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Options";
        };

        environment = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = null;
          description = "Environment";
        };
      };
    }
  );
  # tmuxp doesn't have well-defined defaults, so we need to exclude all null values from the result.
  filterNullAttrs =
    v:
    if isAttrs v then
      filterAttrs (k: v: v != null) (mapAttrs (path: filterNullAttrs) v)
    else if isList v then
      filter (v: v != null) (map filterNullAttrs v)
    else
      v;
  # normalize does the filtering, and then sets defaults.
  normalize =
    name: workspace:
    (filterNullAttrs workspace)
    // lib.optionalAttrs (workspace.session_name == null) {
      session_name = name;
    };
in
{
  options.programs.tmux.tmuxp = {
    package = mkOption {
      type = types.package;
      default = pkgs.tmuxp;
      description = "The tmuxp package to use.";
    };

    workspaces = mkOption {
      type = types.attrsOf workspace;
      default = { };
      description = "List of tmuxp workspaces.";
    };
  };

  config = mkIf cfg.enable {
    home.file = builtins.listToAttrs (
      builtins.attrValues (
        builtins.mapAttrs (name: value: {
          name = ".tmuxp/${name}.yaml";
          value = {
            source = (pkgs.formats.yaml { }).generate name (normalize name value);
          };
        }) cfg.workspaces
      )
    );
  };
}
