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

    # Configure store signing if we have a store key.
    sops.secrets."store-keys/${machine.hostKey}" = {
      mode = "0400";
    };

    # Reference the store key indirectly so nix-daemon can start even when
    # sops hasn't decrypted yet (first boot, or sops failure leaving
    # /run/secrets empty). The include file is populated by the activation
    # script below after setupSecrets runs.
    nix.extraOptions = ''
      !include /etc/nix/store-signing.conf
    '';

    system.activationScripts.storeSigningConf = {
      deps = [ "setupSecrets" ];
      text = ''
        SECRET="${config.sops.secrets."store-keys/${machine.hostKey}".path}"
        if [ -r "$SECRET" ]; then
          printf 'secret-key-files = %s\n' "$SECRET" > /etc/nix/store-signing.conf
        else
          rm -f /etc/nix/store-signing.conf
        fi
        # Pick up the new include without manual intervention. try-restart
        # is a no-op when the unit isn't running (early boot).
        ${pkgs.systemd}/bin/systemctl try-restart nix-daemon.service 2>/dev/null || true
      '';
    };
  };
}
