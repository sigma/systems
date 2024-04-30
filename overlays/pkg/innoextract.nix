final: prev: {
  innoextract =
    (prev.innoextract.overrideAttrs (newAttrs: oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ final.lib.optional final.stdenv.isDarwin [final.iconv];
    }))
    .override {
      withGog = true;
      unar = final.unar;
    };
}
