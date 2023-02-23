(nixpkgs: stable: master: config: final: prev:
    nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") rec {
      x86 = import nixpkgs {
        system = "x86_64-darwin";
        inherit config;
      };
      x86-stable = import stable {
        system = "x86_64-darwin";
        inherit config;
      };
      x86-master = import master {
        system = "x86_64-darwin";
        inherit config;
      };
    })
