# Settings Module System
#
# This module implements an auto-loading settings pattern based on filesystem hierarchy.
#
# ## Structure
# The filesystem structure directly maps to configuration paths:
#   settings/programs/foo.nix     → programs.foo.*
#   settings/programs/bar/baz.nix → programs.bar.baz.*
#   settings/targets/foo.nix      → targets.foo.*
#
# ## Pattern
# Each settings file (e.g., settings/programs/bat.nix) exports the configuration
# FOR that program. The file should set `enable = true` if the program should be
# enabled, along with any program-specific settings:
#
#   { pkgs, ... }:
#   {
#     enable = true;  # This is settings/programs/bat.nix, so we're configuring bat
#     config = {
#       style = "numbers,changes,header";
#     };
#   }
#
# ## Conditionals
# Settings can use machine features for conditional configuration:
#
#   { machine, ... }:
#   {
#     enable = machine.features.some-flag;  # Only enable on certain machines
#     # ... settings
#   }
#
# ## Loader Mechanism
# The `loader` function automatically discovers and imports all .nix files in a directory,
# making them available as attributes matching their filename (minus .nix extension).
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
