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
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "rancher"
    ];

    home-manager.users.${user.login} = {
      programs.k9s.enable = true;

      home = {
        packages = with pkgs; [
          jaq
          jsonnet
          jsonnet-bundler
          stable.mimir
          tanka
          yq-go
          kubectl
          kubeswitch
        ];

        sessionVariables = {
          KUBECONFIG = "$HOME/.kube/config";
        };
      };
    };
  };
}
