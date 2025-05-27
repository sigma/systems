{
  machine,
  lib,
  ...
}: {
  imports =
    lib.optionals machine.features.oplabs [
      ./oplabs.nix
    ]
    ++ lib.optionals machine.features.firefly [
      ./firefly.nix
    ]
    ++ lib.optionals machine.features.laptop [
      ./laptop.nix
    ]
    ++ lib.optionals (!machine.features.laptop && machine.features.mac) [
      ./desktop.nix
    ]
    ++ lib.optionals machine.features.determinate [
      ./determinate.nix
    ];
}
