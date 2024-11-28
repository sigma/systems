{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.kubeswitch;
in {
  options.programs.kubeswitch = {
    enable = mkEnableOption "kubeswitch";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.kubeswitch
    ];

    home.sessionVariables = {
      KUBECONFIG = "$HOME/.kube/config";
    };
  };
}
