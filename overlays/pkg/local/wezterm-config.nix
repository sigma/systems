{
  lib,
  stdenv,
  coreutils,
  findutils,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "wezterm-config";
  version = "dev";
  src = lib.fileset.toSource {
    root = ./wezterm-config;
    fileset = ./wezterm-config;
  };

  tabline = fetchFromGitHub {
    owner = "michaelbrusegard";
    repo = "tabline.wez";
    rev = "v1.6.0";
    sha256 = "sha256-1/lA0wjkvpIRauuhDhaV3gzCFSql+PH39/Kpwzrbk54=";
  };

  smart_workspace_switcher = fetchFromGitHub {
    owner = "MLFlexer";
    repo = "smart_workspace_switcher.wezterm";
    rev = "40228a08e7bffb93b63b131df7f605278b5d8187";
    sha256 = "sha256-LekKmTjKLGBBexsdYeRDo2fZVpYNZ5ISyHoz4UNTmsA=";
  };

  tmux = fetchFromGitHub {
    owner = "sei40kr";
    repo = "wez-tmux";
    rev = "d53fb08b8212d82c34abacfce167bfa79919bb41";
    sha256 = "sha256-6AvgDVBE8iK+yytrH4j16xtRkVYEujukgYMJVRd+mLk=";
  };

  dontUnpack = true;

  buildPhase = ''
    ${coreutils}/bin/cp -R $src/* .

    # plugins
    ${coreutils}/bin/cp -R $tabline/plugin/tabline .
    ${coreutils}/bin/cp -R $smart_workspace_switcher/plugin ./smart_workspace_switcher
    ${coreutils}/bin/cp -R $tmux/plugin ./tmux
  '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
