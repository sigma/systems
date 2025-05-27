{
  lib,
  config,
  ...
}:
with lib; {
  nix.enable = mkForce false;

  # determinate nix config. Only nix.custom.conf can be used to override
  # options.
  environment.etc."nix/nix.custom.conf".text = ''
    # determinate-only options
    lazy-trees = true

    ${config.nix.extraOptions}
  '';
}
