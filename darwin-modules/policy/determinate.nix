{
  config,
  lib,
  user,
  machine,
  nixConfig,
  ...
}:
with lib;
let
  isBuilder = machine.builder != null && machine.builder.enable or false;

  # Devboxes whose parent is this host — exposed as remote builders.
  myDevboxes = filterAttrs (name: b: b.parentHost == machine.hostKey) nixConfig.builders;
  hasMyDevboxes = myDevboxes != { };

  # Format a builder for the nix.conf `builders =` line.
  # Layout: uri systems sshKey maxJobs speedFactor supportedFeatures mandatoryFeatures publicHostKey
  formatBuilder = name: b:
    let
      host = if b.alias != null then b.alias else b.name;
      sshKeyPath = config.sops.secrets."builder-keys/${name}".path;
      features = if b.supportedFeatures == [ ] then "-" else concatStringsSep "," b.supportedFeatures;
      pubKey = if b.publicHostKey != null then b.publicHostKey else "-";
    in
    "ssh-ng://${b.sshUser}@${host} ${b.system} ${sshKeyPath} ${toString b.maxJobs} ${toString b.speedFactor} ${features} - ${pubKey}";

  buildersLine = concatStringsSep " ; " (mapAttrsToList formatBuilder myDevboxes);

  # Devbox store signing keys to trust (so signed paths from the devbox are accepted)
  myDevboxStoreKeys = filter (k: k != null) (
    mapAttrsToList (_: b: b.storePublicKey) myDevboxes
  );
in
{
  config = mkIf machine.features.determinate {
    # disable nix management as we're using determinate nix.
    nix.enable = mkForce false;

    # determinate nix config. Only nix.custom.conf can be used to override
    # options.
    environment.etc."nix/nix.custom.conf".text = ''
      # Allow user to override restricted settings
      trusted-users = root ${user.login}

      ${lib.optionalString machine.features.mac ''
        # Determinate Nix Linux Builder
        extra-experimental-features = external-builders
        external-builders = [{"systems":["aarch64-linux","x86_64-linux"],"program":"/usr/local/bin/determinate-nixd","args":["builder"]}]
      ''}

      ${lib.optionalString hasMyDevboxes ''
        # Distributed builds via this host's devbox(es)
        builders = ${buildersLine}
        builders-use-substitutes = true
        ${lib.optionalString (myDevboxStoreKeys != [ ]) ''
          extra-trusted-public-keys = ${concatStringsSep " " myDevboxStoreKeys}
        ''}
      ''}

      ${config.nix.extraOptions}

      ${lib.optionalString isBuilder ''
        # Store signing for this builder
        secret-key-files = ${config.sops.secrets."store-keys/${machine.hostKey}".path}
      ''}
    '';

    # restore ability to populate registry, which is normally guarded by
    # nix.enable.
    environment.etc."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = mapAttrsToList (n: v: { inherit (v) from to exact; }) config.nix.registry;
    };
  };
}
