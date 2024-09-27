{
  machine,
  lib,
  ...
}: {
  imports = lib.optionals machine.features.google [
    ./google.nix
  ];
}
