{
  lib,
  machine,
  config,
  ...
}:
with lib;
{
  config = mkIf machine.features.determinate {
    # disable nix management as we're using determinate nix.
    nix.enable = mkForce false;

    # determinate nix config. Only nix.custom.conf can be used to override
    # options.
    environment.etc."nix/nix.custom.conf".text = ''
      ${lib.optionalString machine.features.mac ''
        # Determinate Nix Linux Builder
        extra-experimental-features = external-builders
        external-builders = [{"systems":["aarch64-linux","x86_64-linux"],"program":"/usr/local/bin/determinate-nixd","args":["builder"]}]
      ''}

      ${config.nix.extraOptions}
    '';

    # restore ability to populate registry, which is normally guarded by
    # nix.enable.
    environment.etc."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = mapAttrsToList (n: v: { inherit (v) from to exact; }) config.nix.registry;
    };
  };
}
