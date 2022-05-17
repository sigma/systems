(input: final: prev: {
  comma = input.packages.${prev.stdenv.system}.comma.overrideAttrs (oldAttrs: rec {
    patches = (oldAttrs.patches or []) ++ [
      (prev.fetchpatch {
        url = "https://github.com/sigma/comma/commit/7b024f4ad44796572bbdb4d71861a0bb3130ba49.patch";
        sha256 = "sha256-bbJNhjgfLza3nLbmtMruC5w7bL33pdfXf28bqgHbAoE=";
      })
    ];
  });
})
