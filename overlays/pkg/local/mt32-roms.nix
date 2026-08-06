{
  stdenv,
  lib,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  pname = "mt32-roms";
  version = "1.0";

  src = fetchzip {
    url = "https://archive.org/download/Roland-MT-32-ROMs/roland-mt-32-roms.zip";
    hash = "sha256-CG6m7EFCa3hU8+Do0qOO9rXABF4R48B8kW4EAOiYNRA=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out
    # The zip contains MT-32 ROM files directly at the root
    cp -r $src/mt32pi/* $out/
  '';

  meta = with lib; {
    description = "Roland MT-32 ROM files for DOSBox";
    license = licenses.unfreeRedistributable;
    platforms = platforms.all;
    maintainers = [ ];
  };
}
