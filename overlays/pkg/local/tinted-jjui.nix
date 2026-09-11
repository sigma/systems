# jjui colour themes generated from the tinted-theming base16/base24 schemes —
# the collection the jjui theme docs point at. Installs every theme as
# share/jjui/themes/<name>.toml so a directory can be linked straight into
# jjui's config dir; select one with `ui.theme = "<name>"`.
{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "tinted-jjui";
  version = "0-unstable-2026-08-10";

  src = fetchFromGitHub {
    owner = "vic";
    repo = "tinted-jjui";
    rev = "5f9f991e3fe4401de64af8097f729c295098588c";
    hash = "sha256-0nei3ZcdNTkoHEzMG4ofZlaaP3co6UprwtMhli1e2Rc=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/jjui
    cp -r themes $out/share/jjui/themes
    runHook postInstall
  '';

  meta = {
    description = "jjui themes from base16 and base24 colour schemes";
    homepage = "https://github.com/vic/tinted-jjui";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
