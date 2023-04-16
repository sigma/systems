inputs: config:
(let
  extra = pkgset: import pkgset {
    system = "x86_64-darwin";
    inherit config;
  };
in
  final: prev:
  inputs.nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
    x86 = extra inputs.nixpkgs;
    x86-stable = extra inputs.stable;
    x86-master = extra inputs.master;
  })
