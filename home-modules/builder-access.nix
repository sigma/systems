# Builder access configuration for home-manager
# Adds builder SSH public keys to authorized_keys when this machine is a builder.
{
  lib,
  machine,
  nixConfig,
  ...
}:
with lib;
let
  # Check if this machine is configured as a builder
  isBuilder = machine.builder != null && machine.builder.enable or false;

  # Collect all builder SSH public keys (for authorized_keys)
  # This allows other machines to connect to this machine for builds
  allBuilderPublicKeys = filter (k: k != null) (
    mapAttrsToList (name: b: b.sshPublicKey) nixConfig.builders
  );
in
{
  config = mkIf (isBuilder && machine.features.mac) {
    # Add builder SSH keys to user's authorized_keys on darwin
    # (NixOS uses the system-level nixbuilder user instead)
    home.file.".ssh/authorized_keys".text = mkAfter (
      concatStringsSep "\n" allBuilderPublicKeys + "\n"
    );
  };
}
