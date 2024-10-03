{
  config,
  user,
  lib,
  ...
}: let
  cfg = config.programs.secretive;
in
  with lib; {
    options.programs.secretive = {
      enable = mkEnableOption "secretive";

      globalAgentIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to integrate with the global agent.";
      };

      zshIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to integrate with the zsh shell.";
      };
    };

    config = mkIf cfg.enable {
      homebrew.casks = [
        {
          name = "secretive";
          args = {appdir = "/Applications";};
        }
      ];

      home-manager.users.${user.login} = let
        secretiveSocket = "/Users/${user.login}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      in {
        programs.ssh = mkIf cfg.globalAgentIntegration {
          extraConfig = ''
            IdentityAgent ${secretiveSocket}
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
