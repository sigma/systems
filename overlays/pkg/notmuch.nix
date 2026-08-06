final: prev: {
  notmuch =
    (prev.notmuch.overrideAttrs (
      newAttrs: oldAttrs: {
        doCheck = false;
      }
    )).override
      {
        withRuby = false;
        withEmacs = false;
      };
}
