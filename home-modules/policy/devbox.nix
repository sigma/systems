# Devbox policy: tools that should be present on every devbox so the parent
# can use it transparently.
{
  lib,
  machine,
  ...
}:
lib.mkIf (machine.features.devbox or false) {
  # Symlink Zed's remote-server binary into ~/.zed_server/ so the parent's
  # Zed can connect without the lazy first-time download.
  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;
  };
}
