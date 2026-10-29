# Machine/feature facts (ABox) for ontology/nebula.ttl, generated from the
# flake so hosts.nix stays the single source of truth.
#
#   nix eval --raw --impure --expr \
#     'import ./ontology/facts.nix (builtins.getFlake "git+file://'$PWD'")'
#
# One node per managed machine: the features it declares (input layer of the
# feature seam) and the content features its home config resolves on.
flake:
let
  inherit (builtins)
    attrNames
    attrValues
    concatStringsSep
    filter
    map
    mapAttrs
    toJSON
    ;
  nx = "https://github.com/sigma/systems/ontology/nebula#";
  featIri = name: "<https://github.com/sigma/systems/ontology/feature/${name}>";
  machineIri = name: "<https://github.com/sigma/systems/ontology/machine/${name}>";

  registry = import ../modules/content-features.nix;
  isContent = f: builtins.elem f registry;

  machines = mapAttrs (
    _: sys:
    let
      args = sys.config.home-manager.extraSpecialArgs;
      resolved = sys.config.home-manager.users.${args.user.login}.features;
    in
    {
      inherit (args.machine) hostKey system features;
      enabled = filter (f: resolved.${f}.enable) (attrNames resolved);
    }
  ) (flake.darwinConfigurations // flake.nixosConfigurations);

  # Every feature any machine knows of (machine.features maps all of them).
  allFeatures = attrNames (builtins.foldl' (acc: m: acc // m.features) { } (attrValues machines));

  objects = iris: concatStringsSep ", " iris;

  featureTriples = f: ''
    ${featIri f} a <${nx}${if isContent f then "ContentFeature" else "StructuralFeature"}> ;
        <http://www.w3.org/2000/01/rdf-schema#label> ${toJSON f} .
  '';

  machineTriples =
    m:
    let
      declared = filter (f: m.features.${f}) (attrNames m.features);
    in
    ''
      ${machineIri m.hostKey} a <${nx}Machine> ;
          <${nx}hostKey> ${toJSON m.hostKey} ;
          <${nx}system> ${toJSON m.system}${
            if declared == [ ] then "" else " ;\n    <${nx}declares> ${objects (map featIri declared)}"
          }${if m.enabled == [ ] then "" else " ;\n    <${nx}enables> ${objects (map featIri m.enabled)}"} .
    '';
in
concatStringsSep "\n" (map featureTriples allFeatures ++ map machineTriples (attrValues machines))
