final: prev: {
  innoextract =
    (prev.innoextract.overrideAttrs (
      newAttrs: oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ final.lib.optionals final.stdenv.isDarwin [ final.iconv ];
      }
    )).override
      {
        withGog = true;
        inherit (final) unar;
      };
}
