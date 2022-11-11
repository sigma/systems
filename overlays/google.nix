final: prev:

let
  gitPath = if final.stdenv.isDarwin then "/usr/local/git/current/bin" else "/usr/bin";
  gitGooglePath = if final.stdenv.isDarwin then "/usr/local/git/git-google/bin" else "/usr/bin";
  figPath = if final.stdenv.isDarwin then "/usr/local/bin" else "/usr/bin";
  gcertPath = "/usr/local/bin";
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
      for helper in ${gitPath}/{git,gob}*; do
        bin=`basename $helper`
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${gitPath}/$bin
      done
      for helper in ${gitGooglePath}/{git,gob}*; do
        bin=`basename $helper`
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${gitGooglePath}/$bin
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
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${figPath}/$bin
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
        makeWrapper ${final.nativeWrapper}/bin/native-wrapper $out/bin/$bin --set NATIVE_WRAPPER_BIN ${gcertPath}/$bin
      done

      cat > $out/bin/gcert_renew.command <<EOF
      #!/bin/sh

      # Helper for ensuring we have gcert by using a Terminal window to prompt for it if needed.

      # This is a .command file. Invoking it using:
      #   open -W -n ~/bin/re_gcert_helper.command
      # This will create a new Terminal instance and a new Terminal window for the prompt.
      # When gcert exits, the window and the Terminal instance will close.

      # Sources:
      # https://yaqs.corp.google.com/eng/q/6704876541837312
      # https://stackoverflow.com/questions/989349/running-a-command-in-a-new-mac-os-x-terminal-window
      # https://apple.stackexchange.com/questions/322938/close-terminal-using-exit-when-only-one-window-is-present-close-window-otherw
      # https://stackoverflow.com/questions/26770568/vs-with-the-test-command-in-bash

      gcert; osascript -e 'tell application "Terminal" to quit' &
      EOF
      chmod a+x $out/bin/gcert_renew.command
    '';
  };
}
