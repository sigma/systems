{
  python3,
  lib,
}:
let
  shtab = python3.pkgs.shtab;
in
python3.pkgs.buildPythonApplication {
  pname = "m3ugen";
  version = "0.1.0";
  format = "other";

  src = ./m3ugen;

  dontBuild = true;

  nativeBuildInputs = [ shtab ];
  nativeCheckInputs = [ python3.pkgs.pytest ];

  checkPhase = ''
    runHook preCheck
    pytest test_m3ugen.py -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 m3ugen.py $out/bin/m3ugen

    # Generate shell completions from argparse parser
    PYTHONPATH=.:$PYTHONPATH
    shtab --shell bash m3ugen.get_parser > m3ugen.bash
    shtab --shell zsh  m3ugen.get_parser > _m3ugen
    python3 gen_fish_completions.py > m3ugen.fish

    install -Dm644 m3ugen.bash $out/share/bash-completion/completions/m3ugen
    install -Dm644 _m3ugen     $out/share/zsh/site-functions/_m3ugen
    install -Dm644 m3ugen.fish $out/share/fish/vendor_completions.d/m3ugen.fish
    runHook postInstall
  '';

  meta = with lib; {
    description = "Generate .m3u8 playlists from a directory of audio files";
    license = licenses.mit;
    mainProgram = "m3ugen";
  };
}
