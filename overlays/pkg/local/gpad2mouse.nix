{
  lib,
  swift,
  swiftpm,
  swiftPackages,
}:

swiftPackages.stdenv.mkDerivation {
  pname = "gpad2mouse";
  version = "0.1.0";

  src = ./gpad2mouse;

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  makeFlags = [ "prefix=$(out)" ];

  meta = {
    description = "Gamepad-to-mouse daemon for macOS using Game Controller framework";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "gpad2mouse";
  };
}
