{
  config,
  pkgs,
  lib,
  machine,
  user,
  ...
}:
let
  loader =
    dir:
    builtins.listToAttrs (
      map
        # foo.nix -> programs.foo = ...
        (p: {
          name = lib.removeSuffix ".nix" p;
          value = import ./${dir}/${p} {
            inherit
              config
              pkgs
              lib
              machine
              user
              ;
          };
        })
        (
          builtins.filter
            # all .nix files, present company excluded
            (f: (lib.hasSuffix ".nix" f))
            # in directory dir
            (builtins.attrNames (builtins.readDir ./${dir}))
        )
    );
in
{
  programs = loader "programs";
  targets = loader "targets";
}
