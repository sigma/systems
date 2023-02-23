final: prev: {
  afsctool = prev.afsctool.overrideAttrs (old: rec {
    version = "1.7.3";
    src = final.fetchFromGitHub {
      owner = "RJVB";
      repo = old.pname;
      rev = "v${version}";
      hash = "sha256-cZ0P9cygj+5GgkDRpQk7P9z8zh087fpVfrYXMRRVUAI=";
    };
  });
}
