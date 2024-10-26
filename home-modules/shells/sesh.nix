{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.sesh;
in {
  options = {
    programs.sesh = {
      enable = mkEnableOption "Enable sesh";

      enableTmuxpWorkspaces = mkEnableOption "Enable tmuxp workspaces";

      package = mkOption {
        type = types.package;
        default = pkgs.sesh;
        defaultText = "pkgs.sesh";
        description = "The sesh package to use.";
      };

      enableTmuxIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tmux integration.";
      };

      useIcons = mkOption {
        type = types.bool;
        default = true;
        description = "Use icons in sesh.";
      };

      sessions = mkOption {
        type = types.listOf (types.submodule {
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
        });
        default = [];
        description = "List of managed sessions.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    home.file.".config/sesh/sesh.toml".source = (pkgs.formats.toml {}).generate "sesh.toml" {
      session =
        map (session: {
          name = session.name;
          path = session.path;
          startup_command = pkgs.writeShellScript "sesh-${session.name}-startup.sh" session.startupScript;
        })
        cfg.sessions;
    };

    programs.tmux = mkIf cfg.enableTmuxIntegration {
      extraConfig = let
        sesh = "${cfg.package}/bin/sesh";
        fzf-tmux = "${pkgs.fzf}/bin/fzf-tmux";
        seshList = "${sesh} list ${
          if cfg.useIcons
          then "-i"
          else ""
        }";
        killSession = pkgs.writeShellScript "sesh-kill-session.sh" ''
          name=''${1${
            if cfg.useIcons
            then ":2"
            else ""
          }}
          ${pkgs.tmux}/bin/tmux kill-session -t "$name"
        '';
      in ''
        bind-key "T" run-shell "${sesh} connect \"$(
         ${seshList} -c -t -H | ${fzf-tmux} -p 55%,60% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^g configs ^d tmux kill' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(${seshList} -c -t -H)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(${seshList} -t -H)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(${seshList} -c -H)' \
          --bind 'ctrl-d:execute(${killSession} {})+change-prompt(⚡  )+reload(${seshList} -c -t -H)'
        )\""

        bind-key "L" run-shell "${sesh} last"
      '';
    };

    programs.sesh.sessions = let
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
