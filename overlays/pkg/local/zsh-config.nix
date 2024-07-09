{
  stdenv,
  lib,
  coreutils,
  findutils,
  writeText,
  nix-filter,
  google ? false,
}:
stdenv.mkDerivation {
  pname = "zsh-config";
  version = "dev";
  src = nix-filter {
    root = ./.;
    include = [
      (nix-filter.inDirectory ./zsh-config)
    ];
    exclude = lib.optionals (!google) [
      ./zsh-config/google.plugin.zsh
    ];
  };
  dontUnpack = true;

  buildPhase = let
    gcertCookie =
      if stdenv.system == "x86_64-linux"
      then "/var/run/ccache/sso-$USER/cookie"
      else "$HOME/.sso/cookie";
    generated = writeText "p10k.generated.config.zsh" ''
      # location of the gcert cookie
      typeset -g POWERLEVEL9K_CERT_COOKIE_FILE="${gcertCookie}"
    '';
  in
    ''
      ${coreutils}/bin/cp -R $src/zsh-config/* .
    ''
    + lib.optionalString google ''
      ${coreutils}/bin/cp ${generated} ./p10k.generated.config.zsh
    '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
