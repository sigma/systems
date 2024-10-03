{pkgs, ...}: {
  userSettings = {
    "vscode-kubernetes.helm-path" = "${pkgs.kubernetes-helm}/bin/helm";
    "vscode-kubernetes.kubectl-path" = "${pkgs.kubectl}/bin/kubectl";
    "vscode-kubernetes.minikube-path" = "${pkgs.minikube}/bin/minikube";
  };
}
