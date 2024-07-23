{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.tmux.tmuxp;

  pane = types.submodule ({...}: {
    options = {
      focus = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to focus this pane";
      };
    };
  });
  window = types.submodule ({...}: {
    options = {
      window_name = mkOption {
        type = types.str;
        description = "The name of the window";
      };

      panes = mkOption {
        type = types.listOf pane;
        description = "List of panes";
      };
    };
  });
  workspace = types.submodule ({...}: {
    options = {
      session_name = mkOption {
        type = types.str;
        default = "";
        description = "The name of the session";
      };

      start_directory = mkOption {
        type = types.str;
        description = "The base directory";
      };

      windows = mkOption {
        type = types.listOf window;
        description = "List of windows";
      };
    };
  });
  normalize = name: workspace:
    workspace
    // lib.optionalAttrs (workspace.session_name == "") {
      session_name = name;
    };
in {
  options.programs.tmux.tmuxp = {
    workspaces = mkOption {
      type = types.attrsOf workspace;
      description = "List of tmuxp workspaces.";
    };
  };

  config = mkIf cfg.enable {
    home.file = builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs (name: value: {
        name = ".tmuxp/${name}.yaml";
        value = {
          source = (pkgs.formats.yaml {}).generate name (normalize name value);
        };
      })
      cfg.workspaces));
  };
}
