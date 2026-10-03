# Tool modules, auto-discovered.
#
# One module per tool: it declares the tool's options, sets its values, and
# gates itself (on a content feature, a structural feature, or its own enable
# set by a policy). Every *.nix file here is imported, composed in sorted
# filename order the same way overlays/pkg is (ADR 0003) — module merging makes
# the order immaterial anyway. Tools configured purely through an upstream
# home-manager module live in ../settings/programs/ instead.
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (
      name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
    ))
    builtins.attrNames
    (map (name: ./${name}))
  ];
}
