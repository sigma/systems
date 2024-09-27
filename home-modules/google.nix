{
  machine,
  lib,
  ...
}:
lib.optionalAttrs machine.features.google {
  imports = [
    ./blaze.nix
    ./gcert.nix
  ];

  programs = {
    blaze.enable = true;
    gcert.enable = true;
  };
}
