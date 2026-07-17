# Centralized font preferences.
#
# Editors, terminals, and other consumers read `programs.fontProfiles.<name>`
# (e.g. `editor`, `terminal`, `ui`) and translate the resolved profile to
# their own settings shape. Each profile references catalog entries from
# `programs.fontCatalog` so font names stay tied to the packages providing
# them; profile-referenced packages are auto-installed via `home.packages`.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  catalog = import ./catalog.nix { inherit pkgs; };

  fontRefType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
      };
      family = mkOption { type = types.str; };
    };
  };

  # Fallbacks may be a catalog ref or a plain string for system fonts
  # (e.g. "Menlo", "monospace") that no nix package provides.
  fallbackType = types.either types.str fontRefType;
  fbPackage = f: if isString f then null else f.package;

  profileType = types.submodule {
    options = {
      family = mkOption { type = fontRefType; };
      fallbacks = mkOption {
        type = types.listOf fallbackType;
        default = [ ];
      };
      size = mkOption { type = types.int; };
      weight = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      features = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };
in
{
  options.programs.fontCatalog = mkOption {
    type = types.attrsOf fontRefType;
    default = catalog;
    readOnly = true;
    description = "Available fonts paired with their user-visible family names.";
  };

  options.programs.fontProfiles = mkOption {
    type = types.attrsOf profileType;
    default = { };
    description = "Named font profiles consumable by editors, terminals, etc.";
  };

  # Fonts belong to the graphical content feature: a headless devbox has no GUI
  # consumer for them (see CONTEXT.md).
  config.home.packages = mkIf config.features.graphical.enable (
    unique (
      filter (p: p != null) (
        concatMap (p: [ p.family.package ] ++ map fbPackage p.fallbacks) (
          attrValues config.programs.fontProfiles
        )
      )
    )
  );
}
