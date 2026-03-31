{
  lib,
  rustPlatform,
  apple-sdk_15,
  pkg-config,
}:

rustPlatform.buildRustPackage {
  pname = "gpad2mouse";
  version = "0.1.0";

  src = ./gpad2mouse;

  cargoHash = "sha256-zxTz89aMH5GG8E/khwihddL+d1hrflY8IN+EuwdeEiQ=";

  buildInputs = [
    apple-sdk_15
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  postInstall = ''
    mkdir -p $out/Applications/gpad2mouse.app/Contents/MacOS
    cp $out/bin/gpad2mouse $out/Applications/gpad2mouse.app/Contents/MacOS/
    cp ${./gpad2mouse/Info.plist} $out/Applications/gpad2mouse.app/Contents/Info.plist
  '';

  meta = {
    description = "Gamepad-to-mouse daemon for macOS using Game Controller framework";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "gpad2mouse";
  };
}
