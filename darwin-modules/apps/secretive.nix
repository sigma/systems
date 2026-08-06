{
  config,
  user,
  lib,
  ...
}:
let
  cfg = config.programs.secretive;
  homeDir = config.users.users.${user.login}.home;
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

    user =
      let
        secretiveSocket = "${homeDir}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      in
      {
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
