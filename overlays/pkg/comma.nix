final: prev: {
  comma = prev.comma.overrideAttrs (oldAttrs: rec {
    patches =
      (oldAttrs.patches or [])
      ++ [
        (prev.fetchpatch {
          url = "https://github.com/sigma/comma/commit/1fcb07d14c9b433b3fa3840984ba18ab64e3154b.patch";
          sha256 = "sha256-K3hj5aAwCYU/ffj/RqkcBQ0xMfvmcLckIhSXBr/3Z4Q=";
        })
      ];
  });
}
