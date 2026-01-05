{
  config,
  pkgs,
  lib,
  machine,
  user,
  nixConfig,
  ...
}:
let
  isBuilder = machine.builder != null && machine.builder.enable or false;
in
{
  nix.enable = !machine.features.determinate;

  # Add user to trusted-users for ad-hoc builder overrides
  nix.settings.trusted-users = [ user.login ];

  nix.extraOptions =
    let
      substituters = lib.concatStringsSep " " nixConfig.trusted-substituters;
      publicKeys = lib.concatStringsSep " " nixConfig.trusted-public-keys;
    in
    ''
      auto-optimise-store = true
      allow-import-from-derivation = true
      warn-dirty = false

      download-attempts = 10
      connect-timeout = 10

      substituters = ${substituters}
      trusted-public-keys = ${publicKeys}
    ''
    + lib.optionalString (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    ''
    # Store signing for non-determinate darwin builders
    + lib.optionalString (isBuilder && !machine.features.determinate) ''
      secret-key-files = ${config.sops.secrets."store-keys/${machine.hostKey}".path}
    '';

  # Configure store signing secret if this machine is a builder
  sops.secrets."store-keys/${machine.hostKey}" = lib.mkIf isBuilder {
    mode = "0400";
  };

  programs.nix-index.enable = true;

  system.primaryUser = user.login;
}
