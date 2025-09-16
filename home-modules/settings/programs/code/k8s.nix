{
  pkgs,
  extSet,
  ...
}:
{
  userSettings = {
    "vscode-kubernetes.helm-path" = "${pkgs.kubernetes-helm}/bin/helm";
    "vscode-kubernetes.kubectl-path" = "${pkgs.kubectl}/bin/kubectl";
    "vscode-kubernetes.minikube-path" = "${pkgs.minikube}/bin/minikube";

    "[yaml]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "redhat.telemetry.enabled" = false;
  };

  extensions = with extSet.vscode-marketplace; [
    ms-kubernetes-tools.vscode-kubernetes-tools
    redhat.vscode-yaml
  ];
}
