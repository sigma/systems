{
  stdenv,
  lib,
  fetchFromGitHub,
  gcc,
}:
stdenv.mkDerivation rec {
  pname = "mdloader";
  version = "1.0.7";

  src = fetchFromGitHub {
    owner = "Massdrop";
    repo = "mdloader";
    rev = version;
    sha256 = "sha256-ydi9XMHztmechVEfXD5gT0Solk3D2CGAp69xvXK5iYk=";
  };

  buildInputs = [
    gcc
  ];

  makeFlags = [ "all" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp build/mdloader $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Massdrop keyboard firmware loader";
    homepage = "https://github.com/Massdrop/mdloader";
    license = licenses.gpl3;
    platforms = platforms.unix;
    maintainers = [ sigma ];
  };
}
