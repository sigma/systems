# Devbox policy: tools that should be present on every devbox so the parent
# can use it transparently.
{
  lib,
  pkgs,
  machine,
  ...
}:
lib.mkIf (machine.features.devbox or false) {
  # We want HM's installRemoteServer to symlink the remote-server binary, but
  # the full Zed editor binary is useless on a headless Linux VM. Replace the
  # editor's `package` with a stub that has the same `version` + `remote_server`
  # passthru (so HM still computes the right binary name), but whose `bin/zed`
  # is a no-op symlink.
  programs.zed-editor = {
    # Disabled while not actively using Zed; flip back to true to get
    # the remote-server stub on devboxes for the parent to connect.
    enable = false;
    installRemoteServer = true;
    package = pkgs.runCommand "zed-editor-stub-${pkgs.zed-editor.version}" {
      passthru = { inherit (pkgs.zed-editor) version remote_server; };
    } ''
      mkdir -p $out/bin
      # coreutils' /bin/true is a multi-call binary that dispatches on
      # argv[0], so symlinking it as `zed` errors out. Use a tiny noop script.
      cat > $out/bin/zed <<'EOF'
      #!/bin/sh
      exit 0
      EOF
      chmod +x $out/bin/zed
      ln -s zed $out/bin/zeditor
    '';
  };
}
