{ lib, machine, ... }:
with lib;
{
  config = mkIf machine.features.work {
    features.ipfs.enable = mkForce false;

    programs.onepassword.enable = mkForce true;

    # Shared "Work" workspace; each work policy routes its own Chrome profile
    # window here (see firefly.nix / arbora.nix).
    programs.aerospace.workspaces = mkBefore [
      {
        name = "W"; # Work
        display = "main";
      }
    ];
  };
}
