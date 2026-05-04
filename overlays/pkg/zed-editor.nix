# Override the zed-editor package (already replaced by inputs.zed in
# overlays/default.nix) to also build the remote_server crate and expose it
# as `passthru.remote_server` so home-manager's
# `programs.zed-editor.installRemoteServer = true` can symlink it.
#
# The zed flake uses crane and bakes its cargo args into `buildPhase`, so
# overriding `cargoExtraArgs` does nothing. We do a second cargo invocation
# in `postBuild` and install the resulting binary in `postInstall`.
final: prev:
let
  inherit (prev.zed-editor) version;

  zed-editor-with-remote = prev.zed-editor.overrideAttrs (old: {
    postBuild = (old.postBuild or "") + ''
      cargoWithProfile build \
        --locked \
        --features=gpui_platform/runtime_shaders \
        -p remote_server
    '';

    postInstall = (old.postInstall or "") + ''
      install -Dm755 "$TARGET_DIR/remote_server" \
        "$out/bin/zed-remote-server-stable-${version}"
    '';
  });
in
{
  zed-editor = zed-editor-with-remote.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      remote_server = final.runCommand "zed-remote-server-${version}" { } ''
        install -Dm755 \
          "${zed-editor-with-remote}/bin/zed-remote-server-stable-${version}" \
          "$out/bin/zed-remote-server-stable-${version}"
      '';
    };
  });
}
