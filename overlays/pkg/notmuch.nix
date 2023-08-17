final: prev: {
  notmuch = (prev.notmuch.overrideAttrs (newAttrs: oldAttrs: {
    doCheck = false;

    postConfigure = ''
      mkdir ${placeholder "bindingconfig"}
      cp version.txt ${placeholder "bindingconfig"}/
    '';
  })).override {
    withRuby = false;
    withEmacs = false;
  };

  python310 = prev.python310.override {
    packageOverrides = pyself: pysuper: {
      notmuch2 = pysuper.notmuch2.overrideAttrs (_: {
        postPatch = ''
          cat > _notmuch_config.py <<EOF
          NOTMUCH_VERSION_FILE='${final.notmuch.bindingconfig}/version.txt'
          NOTMUCH_INCLUDE_DIR='${final.notmuch.out}/include'
          NOTMUCH_LIB_DIR='${final.notmuch.out}/lib'
          EOF
        '';

        meta.broken = false;
      });
    };
  };
}
