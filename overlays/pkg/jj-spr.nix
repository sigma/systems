final: prev: {
  jj-spr = prev.jj-spr.overrideAttrs (oldAttrs: {
    buildInputs = with final; [
      openssl
      pkg-config
      zlib
    ];
  });
}