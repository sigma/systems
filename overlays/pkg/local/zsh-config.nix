{
  stdenv,
  lib,
  coreutils,
  findutils,
  writeText,
  isWork ? false,
}:
stdenv.mkDerivation {
  pname = "zsh-config";
  version = "dev";
  src = ./zsh-config;
  dontUnpack = true;

  buildPhase = let
    gcertCookie =
      if stdenv.system == "x86_64-linux"
      then "/var/run/ccache/sso-$USER/cookie"
      else "$HOME/.sso/cookie";
    generated = writeText "p10k.generated.config.zsh" (lib.optionalString isWork ''
      # location of the gcert cookie
      typeset -g POWERLEVEL9K_CERT_COOKIE_FILE="${gcertCookie}"
    '');
  in
    ''
      ${coreutils}/bin/cp -R $src/* .
      ${coreutils}/bin/cp ${generated} ./p10k.generated.config.zsh
    ''
    + lib.optionalString (!isWork) ''
      ${coreutils}/bin/rm google.plugin.zsh
    '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
