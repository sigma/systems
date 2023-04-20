args@{lib, ...}:
  (builtins.listToAttrs
  (map
    (p: {
      name = (lib.removeSuffix ".nix" p);
      value = (import ./${p} args);
    })
    (builtins.filter
      (f: (lib.hasSuffix ".nix" f) && (f != "default.nix"))
      (builtins.attrNames (builtins.readDir ./.)))))
