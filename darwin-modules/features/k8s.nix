{
  config,
  lib,
  pkgs,
  user,
  ...
}:
with lib; let
  cfg = config.features.k8s;
in {
  options.features.k8s = {
    enable = mkEnableOption "k8s";

    useJsonnet = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use jsonnet for k8s.";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "orbstack"
    ];

    home-manager.users.${user.login} = {
      programs.k9s.enable = true;
      programs.kubeswitch = {
        enable = true;
        shellAlias = "sw";
      };

      programs.fish.shellAliases = {
        "k" = "kubectl";
      };

      home = {
        packages = with pkgs;
          [
            jaq
            mimir
            yq-go

            docker-client
            kubectl
          ]
          ++ lib.optionals cfg.useJsonnet [
            jsonnet
            jsonnet-bundler
            tanka
          ];

        sessionVariables = {
          KUBECONFIG = "$HOME/.kube/config";
        };
      };
    };
  };
}
