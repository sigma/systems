# VS Code Remote SSH support for NixOS
# Reference: https://nixos.wiki/wiki/Visual_Studio_Code#Remote_SSH
{
  config,
  lib,
  machine,
  user,
  ...
}:
with lib;
{
  config = mkIf machine.features.nixos {
    services.vscode-server.enable = true;

    # Watch VS Code (and variants) server directories
    services.vscode-server.installPath = [
      "$HOME/.vscode-server"
      "$HOME/.cursor-server"
      "$HOME/.antigravity-server"
    ];

    # Auto-enable the user service for the machine user
    systemd.user.services.auto-fix-vscode-server.wantedBy = [ "default.target" ];
  };
}
