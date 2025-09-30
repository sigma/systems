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
    rev = "v1.4.0";
    sha256 = "sha256-25kE0K3yWaH6LIPXLAJLpVtwVrIqKxM4Z4LBDkng5g4=";
  };

  smart_workspace_switcher = fetchFromGitHub {
    owner = "MLFlexer";
    repo = "smart_workspace_switcher.wezterm";
    rev = "88b858436fd36b3bff864995233202ddb032a16b";
    sha256 = "sha256-4h31TwQVEd4JMYWwi1Tkn+SEv0vAEwPRbqcyBzd7aBo=";
  };

  tmux = fetchFromGitHub {
    owner = "sei40kr";
    repo = "wez-tmux";
    rev = "c3203e1310ed51895e5492537c1ed90f74664bbb";
    sha256 = "sha256-NXkz4ZdnkVW+BridetN5xJhFcVbXKJeUcbI+oo3d9T8=";
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
