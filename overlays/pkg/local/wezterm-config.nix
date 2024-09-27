{
  stdenv,
  coreutils,
  findutils,
  nix-filter,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "wezterm-config";
  version = "dev";
  src = nix-filter {
    root = ./.;
    include = [
      (nix-filter.inDirectory ./wezterm-config)
    ];
  };
  tabline = fetchFromGitHub {
    owner = "michaelbrusegard";
    repo = "tabline.wez";
    rev = "v1.4.0";
    sha256 = "sha256-25kE0K3yWaH6LIPXLAJLpVtwVrIqKxM4Z4LBDkng5g4=";
  };

  dontUnpack = true;

  buildPhase = ''
    ${coreutils}/bin/cp -R $src/wezterm-config/* .
    ${coreutils}/bin/cp -R $tabline/plugin/tabline .
  '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
