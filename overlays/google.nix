final: prev:

let
  gitPath = if final.stdenv.isDarwin then "/usr/local/git/current/bin/" else "/usr/bin/";
in
{
  # a fake git package that just links to the google-one. To be used in
  # home-manager git config for example.
  gitGoogle = final.stdenv.mkDerivation rec {
    pname = "git";
    version = "goog";

    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for helper in ${gitPath}/{git,gob}*; do
        ln -s $helper $out/bin/
      done
    '';
  };
}
