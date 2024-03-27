final: prev: {
  d2 = prev.d2.overrideAttrs (newAttrs: oldAttrs: {
    doCheck = false;
  });
}
