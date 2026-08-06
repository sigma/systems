{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.sesh;
in
{
  options = {
    programs.sesh = {
      enableTmuxpWorkspaces = mkEnableOption "Enable tmuxp workspaces";

      sessions = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "The name of the session.";
              };

              path = mkOption {
                type = types.str;
                description = "The path to the session.";
              };

              startupScript = mkOption {
                type = types.str;
                default = "";
                description = "The script to run to start the session.";
              };
            };
          }
        );
        default = [ ];
        description = "List of managed sessions.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.sesh.settings = {
      session = map (session: {
        name = session.name;
        path = session.path;
        startup_command = pkgs.writeShellScript "sesh-${session.name}-startup.sh" session.startupScript;
      }) cfg.sessions;
    };

    programs.sesh.sessions =
      let
        tmuxpWorkspace = name: ws: {
          name = ws.session_name;
          path = ws.start_directory;
          startupScript = "${config.programs.tmux.tmuxp.package}/bin/tmuxp load -a ${name}; ${config.programs.tmux.package}/bin/tmux kill-window";
        };
        workspaces = config.programs.tmux.tmuxp.workspaces;
      in
      mkIf cfg.enableTmuxpWorkspaces (builtins.attrValues (builtins.mapAttrs tmuxpWorkspace workspaces));
  };
}
