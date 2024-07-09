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
      # foo.nix -> programs.foo = ...
      (p: {
        name = lib.removeSuffix ".nix" p;
        value = import ./${p} {
          inherit config pkgs lib machine user;
        };
      })
      (builtins.filter
        # all .nix files, present company excluded
        (f: (lib.hasSuffix ".nix" f) && (f != "default.nix"))
        # in current directory
        (builtins.attrNames (builtins.readDir ./.))));
}
