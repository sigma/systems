{
  stdenv,
  coreutils,
  findutils,
  nix-filter,
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
  dontUnpack = true;

  buildPhase = ''
    ${coreutils}/bin/cp -R $src/wezterm-config/* .
  '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
