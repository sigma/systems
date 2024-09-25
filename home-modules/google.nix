{
  machine,
  lib,
  ...
}:
lib.optionalAttrs machine.isWork {
  imports = [
    ./blaze.nix
    ./gcert.nix
  ];

  programs = {
    blaze.enable = true;
    gcert.enable = true;
  };
}
