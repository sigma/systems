final: prev: {
  notmuch = (prev.notmuch.overrideAttrs (newAttrs: oldAttrs: {
    doCheck = false;
  })).override {
    withRuby = false;
    withEmacs = false;
  };

  python310 = prev.python310.override {
    packageOverrides = pyself: pysuper: {
      notmuch2 = pysuper.notmuch2.overrideAttrs (_: {
        meta.broken = false;
      });
    };
  };
}
