final: prev: {
  notmuch = prev.notmuch.override {
    withRuby = false;
    withEmacs = false;
  };
}
