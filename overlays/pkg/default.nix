final: prev:

with prev.lib;
let
  composeOverlays = overlays: final: prev:
    foldl' (flip extends) (const prev) overlays final;
  pkgOverlays = map (p: (import ./${p})) (builtins.filter (f: f != "default.nix") (builtins.attrNames (builtins.readDir ./.)));
in
  composeOverlays pkgOverlays final prev