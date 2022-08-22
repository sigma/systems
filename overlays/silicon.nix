(nixpkgs: config: final: prev: nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") rec {
  pkgs-x86 = import nixpkgs {
    system = "x86_64-darwin";
    inherit config;
  };
  # Sub in x86 version of packages that don't build on Apple Silicon yet
  inherit (pkgs-x86) idris2 lieer;
})
