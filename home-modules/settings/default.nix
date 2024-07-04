{
  config,
  pkgs,
  lib,
  machine,
  user,
  ...
}: {
  programs =
    builtins.listToAttrs
    (map
      (p: {
        name = lib.removeSuffix ".nix" p;
        value = import ./${p} {
          inherit config pkgs lib machine user;
        };
      })
      (builtins.filter
        (f: (lib.hasSuffix ".nix" f) && (f != "default.nix"))
        (builtins.attrNames (builtins.readDir ./.))));
}
