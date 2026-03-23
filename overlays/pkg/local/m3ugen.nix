{
  python3,
  lib,
}:
python3.pkgs.buildPythonApplication {
  pname = "m3ugen";
  version = "0.1.0";
  format = "other";

  src = ./m3ugen;

  dontBuild = true;

  nativeCheckInputs = [ python3.pkgs.pytest ];

  checkPhase = ''
    runHook preCheck
    pytest test_m3ugen.py -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 m3ugen.py $out/bin/m3ugen
    runHook postInstall
  '';

  meta = with lib; {
    description = "Generate .m3u8 playlists from a directory of audio files";
    license = licenses.mit;
    mainProgram = "m3ugen";
  };
}
