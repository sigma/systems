# Provide bun-baseline on x86_64-linux (no AVX2 requirement)
# This allows bun to run on older CPUs like Ivy Bridge (Xeon E5 v2)
#
# To update: run `nix-prefetch-url https://github.com/oven-sh/bun/releases/download/bun-vVERSION/bun-linux-x64-baseline.zip`
# then convert with `nix hash convert --hash-algo sha256 --to sri HASH`
final: prev:
let
  baselineHashes = {
    "1.3.5" = "sha256-a92s1qZYVWmLmBby10hx7aTdC3+pIRQMZEUkj5SnQv0=";
    "1.3.6" = "sha256-GVSr7giQDeYQqLRpL1//psaxXYr959HeTT+Iz8YOfV8=";
  };

  mkBunBaseline =
    bun:
    bun.overrideAttrs (
      oldAttrs:
      let
        version = oldAttrs.version;
        hash =
          baselineHashes.${version}
            or (throw ''
              bun ${version} baseline hash not known.
              Add it to overlays/pkg/bun.nix after running:
                nix-prefetch-url https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip
                nix hash convert --hash-algo sha256 --to sri <hash>
            '');
      in
      {
        src = prev.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
          inherit hash;
        };
        sourceRoot = "bun-linux-x64-baseline";
      }
    );
in
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "x86_64-linux") {
  bun-baseline = mkBunBaseline prev.bun;
}
