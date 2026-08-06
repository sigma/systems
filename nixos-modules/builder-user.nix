# NixOS builder user configuration
# Creates the nixbuilder user that other machines use to connect for remote builds.
{
  config,
  lib,
  pkgs,
  machine,
  nixConfig,
  ...
}:
with lib;
let
  # Check if this machine is configured as a builder
  isBuilder = machine.builder != null && machine.builder.enable or false;

  # Collect all builder SSH public keys (for authorized_keys)
  allBuilderPublicKeys = filter (k: k != null) (
    mapAttrsToList (name: b: b.sshPublicKey) nixConfig.builders
  );
in
{
  config = mkIf isBuilder {
    # Create nixbuilder user for remote build access
    users.users.nixbuilder = {
      isSystemUser = true;
      group = "nixbuilder";
      shell = pkgs.bashInteractive;
      home = "/var/lib/nixbuilder";
      createHome = true;
      openssh.authorizedKeys.keys = allBuilderPublicKeys;
    };

    users.groups.nixbuilder = { };

    # Allow nixbuilder to perform nix operations
    nix.settings.trusted-users = [ "nixbuilder" ];

    # Configure store signing if we have a store key
    # The secret-key-files option tells nix to sign all built paths
    sops.secrets."store-keys/${machine.hostKey}" = {
      mode = "0400";
    };

    nix.settings.secret-key-files = [
      config.sops.secrets."store-keys/${machine.hostKey}".path
    ];
  };
}
