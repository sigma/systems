{
  pkgs,
  extSet,
  ...
}:
{
  userSettings = {
    "bazel.buildifierExecutable" = pkgs.writeShellScriptBin "buildifier" ''
      ${pkgs.bazel-buildtools}/bin/buildifier --warnings=-module-docstring,-function-docstring "$@"
    '';
    "bazel.buildifierFixOnFormat" = true;
    "bazel.executable" = "${pkgs.bazel}/bin/bazel";
  };

  extensions = with extSet.vscode-marketplace; [
    bazelbuild.vscode-bazel
  ];
}
