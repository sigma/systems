{
  config,
  lib,
  user,
  ...
}:
let
  cfg = config.programs.secretive;
  homeDir = config.users.users.${user.login}.home;
  secretiveSocket = "${homeDir}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
in
with lib;
{
  options.programs.secretive = {
    enable = mkEnableOption "secretive";

    globalAgentIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to integrate with the global agent.";
    };

    fishIntegration = mkOption {
      type = types.bool;
      default = config.programs.fish.enable;
      description = "Whether to integrate with the fish shell.";
    };

    zshIntegration = mkOption {
      type = types.bool;
      default = config.programs.zsh.enable;
      description = "Whether to integrate with the zsh shell.";
    };

    launchdIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to set SSH_AUTH_SOCK in the launchd user session, for GUI apps.";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "secretive";
        args = {
          appdir = "/Applications";
        };
      }
    ];

    # GUI apps started from the Dock get only launchd's environment, so set
    # the socket there too: Obsidian's worklog buttons sign their commits.
    launchd.user.agents.secretive-ssh-auth-sock = mkIf cfg.launchdIntegration {
      serviceConfig = {
        ProgramArguments = [
          "/bin/launchctl"
          "setenv"
          "SSH_AUTH_SOCK"
          secretiveSocket
        ];
        RunAtLoad = true;
      };
    };

    user = {
      programs.ssh = mkIf cfg.globalAgentIntegration {
        extraConfig = ''
          IdentityAgent ${secretiveSocket}
        '';
      };

      programs.fish = mkIf cfg.fishIntegration {
        shellInitLast = ''
          set -gx SSH_AUTH_SOCK ${secretiveSocket}
        '';
      };

      programs.zsh = mkIf cfg.zshIntegration {
        initExtra = ''
          export SSH_AUTH_SOCK=${secretiveSocket}
        '';
      };
    };
  };
}
