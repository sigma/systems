{
  swift,
  stdenv,
  lib,
}:
stdenv.mkDerivation {
  pname = "midi-session-manager";
  version = "0.1.0";

  src = ./midi-session-manager;

  nativeBuildInputs = [ swift ];

  # CoreMIDI, Foundation, AppKit frameworks are in the default Darwin SDK

  buildPhase = ''
    runHook preBuild
    swiftc -O -o midi-session-manager main.swift \
      -framework CoreMIDI -framework Foundation -framework AppKit
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp midi-session-manager $out/bin/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Auto-reconnecting MIDI network session manager for macOS";
    platforms = platforms.darwin;
    mainProgram = "midi-session-manager";
  };
}
