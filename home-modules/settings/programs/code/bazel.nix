{
  pkgs,
  extSet,
  ...
}: {
  userSettings = {
    "bazel.buildifierExecutable" = "${pkgs.bazel-buildtools}/bin/buildifier";
    "bazel.buildifierFixOnFormat" = true;
    "bazel.executable" = "${pkgs.bazel}/bin/bazel";
  };

  extensions = with extSet.vscode-marketplace; [
    bazelbuild.vscode-bazel
  ];
}
