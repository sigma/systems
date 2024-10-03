{
  machine,
  lib,
  ...
}: {
  imports =
    lib.optionals machine.features.google [
      ./google.nix
    ]
    ++ lib.optionals machine.features.oplabs [
      ./oplabs.nix
    ];
}
