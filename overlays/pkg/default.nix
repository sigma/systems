final: prev:
with prev.lib;
let
  composeOverlays =
    overlays: final: prev:
    foldl' (flip extends) (const prev) overlays final;
  pkgOverlays =
    map
      # import all files
      (p: (import ./${p}))
      (
        builtins.filter
          # from .nix files, present company excluded
          (f: (prev.lib.hasSuffix ".nix" f) && (f != "default.nix"))
          # from current directory content
          (builtins.attrNames (builtins.readDir ./.))
      );
in
composeOverlays pkgOverlays final prev
