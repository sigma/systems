{
  lib,
  machine,
  config,
  user,
  ...
}:
with lib;
let
  isBuilder = machine.builder != null && machine.builder.enable or false;
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
