{
  machine,
  lib,
  ...
}: {
  imports =
    lib.optionals machine.features.oplabs [
      ./oplabs.nix
    ]
    ++ lib.optionals machine.features.laptop [
      ./laptop.nix
    ];
}
