{pkgs, ...}: {
  userSettings = {
    "bazel.buildifierExecutable" = "${pkgs.bazel-buildtools}/bin/buildifier";
    "bazel.buildifierFixOnFormat" = true;
    "bazel.executable" = "${pkgs.bazel}/bin/bazel";
  };

  extensions = with pkgs.vscode-marketplace; [
    # bazelbuild.vscode-bazel
  ];
}
