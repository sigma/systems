{
  lib,
  user,
  machine,
  ...
}:
with lib;
let
  inherit (import ./lib.nix { inherit lib user; }) mkWorkScopes;
in
{
  config = mkIf machine.features.arbora (mkWorkScopes {
    name = "arbora";
    emailSuffix = "@arbora.partners";
    githubOrgs = [
      "arbora-partners"
    ];
  });
}
