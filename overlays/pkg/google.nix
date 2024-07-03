final: prev: let
  paths =
    {
      gcert = "/usr/bin";
    }
    // (
      if final.stdenv.isDarwin
      then {
        git = "/usr/local/git/current/bin";
        gitExec = "/usr/local/git/current/libexec/git-core";
        gitGoogle = "/usr/local/git/git-google/bin";
        fig = "/usr/local/bin";
      }
      else {
        git = "/usr/bin";
        gitExec = "/usr/lib/git-core";
        gitGoogle = "/usr/bin";
        fig = "/usr/bin";
      }
    );

  helpers = {
    nativeWrapper = final.stdenv.mkDerivation {
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

        chmod a+x $out/bin/*native-wrapper
      '';
    };

    gitGoogleWrapped = final.stdenv.mkDerivation {
      pname = "git";
      version = "goog-wrapped";

      buildInputs = [final.makeWrapper];
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/bin

        # these are all git helpers
        for helper in ${paths.gitExec}/*; do
          ln -s $helper $out/bin/$bin
        done

        # on glinux, these paths contain other binaries, so let's be selective
        for path in ${paths.gitGoogle} ${paths.git}; do
          for helper in $path/{git,gob,scalar}*; do
            bin=`basename $helper`
            ln -sf $helper $out/bin/$bin
          done
        done
      '';
    };
  };
in {
  # a fake git package that just links to the google-one. To be used in
  # home-manager git config for example.
  gitGoogle = final.stdenv.mkDerivation {
    pname = "git";
    version = "goog";

    buildInputs = [final.makeWrapper];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin

      for helper in ${helpers.gitGoogleWrapped}/bin/*; do
        if [ -x $helper ]; then
          bin=`basename $helper`
          makeWrapper ${helpers.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set GIT_EXEC_PATH ${helpers.gitGoogleWrapped}/bin --set NATIVE_WRAPPER_BIN $helper
        fi
      done
    '';
  };

  emacs = final.emacs-unstable;

  fig = final.stdenv.mkDerivation {
    pname = "fig";
    version = "goog";

    buildInputs = [final.makeWrapper];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for bin in chg hg hgd; do
        makeWrapper ${helpers.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.fig}/$bin
      done
    '';
  };

  gcert = final.stdenv.mkDerivation {
    pname = "gcert";
    version = "goog";

    buildInputs = [final.makeWrapper];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      for bin in gcert gcertstatus gcertdestroy; do
        makeWrapper ${helpers.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${paths.gcert}/$bin
      done
    '';
  };
}
