final: prev:

let
  paths = {
    gcert = "/usr/bin";
  } // (if final.stdenv.isDarwin then {
    git = "/usr/local/git/current/bin";
    gitExec ="/usr/local/git/current/libexec/git-core";
    gitGoogle = "/usr/local/git/git-google/bin";
    fig = "/usr/local/bin";
  } else {
    git = "/usr/bin";
    gitExec = "/usr/lib/git-core";
    gitGoogle = "/usr/bin";
    fig = "/usr/bin";
  });

in
{
  nativeWrapper = final.stdenv.mkDerivation rec {
    pname = "native-wrapper";
    version = "goog";

    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/native-wrapper << 'EOF'
      #!/bin/sh
      if test -x "$NATIVE_WRAPPER_BIN"; then
        exec "$NATIVE_WRAPPER_BIN" "$@"
      fi
      echo "$NATIVE_WRAPPER_BIN is not installed."
      exit 1
      EOF

      chmod a+x $out/bin/native-wrapper
    '';
  };

  # a fake git package that just links to the google-one. To be used in
  # home-manager git config for example.
  gitGoogle = final.stdenv.mkDerivation rec {
    pname = "git";
    version = "goog";

    buildInputs = [ final.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for helper in ${paths.git}/{git,gob}*; do
        bin=`basename $helper`
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.git}/$bin --set GIT_EXEC_PATH ${paths.gitExec}:${paths.gitGoogle}
      done
      for helper in ${paths.gitGoogle}/{git,gob}*; do
        bin=`basename $helper`
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.gitGoogle}/$bin
      done
    '';
  };

  fig = final.stdenv.mkDerivation rec {
    pname = "fig";
    version = "goog";

    buildInputs = [ final.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for bin in chg hg hgd; do
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.fig}/$bin
      done
    '';
  };

  gcert = final.stdenv.mkDerivation rec {
    pname = "gcert";
    version = "goog";

    buildInputs = [ final.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for bin in gcert gcertstatus gcertdestroy; do
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.gcert}/$bin
      done
    '';
  };
}
