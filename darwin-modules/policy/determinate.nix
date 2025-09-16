{
  lib,
  config,
  ...
}:
with lib;
{
  # disable nix management as we're using determinate nix.
  nix.enable = mkForce false;

  # determinate nix config. Only nix.custom.conf can be used to override
  # options.
  environment.etc."nix/nix.custom.conf".text = ''
    # determinate-only options
    lazy-trees = true

    ${config.nix.extraOptions}
  '';

  # restore ability to populate registry, which is normally guarded by
  # nix.enable.
  environment.etc."nix/registry.json".text = builtins.toJSON {
    version = 2;
    flakes = mapAttrsToList (n: v: { inherit (v) from to exact; }) config.nix.registry;
  };
}
