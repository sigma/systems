{
  cfg,
  lib,
  ...
}:
let
  # Canonical content-feature registry (see CONTEXT.md). Used to project a
  # host's declared features onto the resolved home feature seam.
  contentFeatures = import ../content-features.nix;

  # SSH-reachability projection of the topology (see CONTEXT.md).
  topology = import ./topology.nix { inherit lib; };

  # helper module to provide a shortcut for home-manager config.
  bridgeModule =
    args@{ user, ... }:
    ((lib.mkAliasOptionModule [ "user" ] [ "home-manager" "users" "${user.login}" ]) args);

in
{
  expandUser =
    user:
    user
    // rec {
      allEmails = builtins.concatMap (prof: prof.emails) user.profiles;
      email = builtins.head allEmails;
      aliases = builtins.tail allEmails;
    };

  hostMachine =
    hostKey: host:
    let
      mapFeatures =
        features: val:
        (builtins.listToAttrs (
          map (feature: {
            name = feature;
            value = val;
          }) features
        ));
      # Derive features from devbox config
      devboxFeatures =
        if host.devbox != null then
          [ "devbox" ]
          ++ lib.optional (host.devbox.hypervisor == "tart") "tart"
          ++ lib.optional (host.devbox.hypervisor == "kvm") "kvm"
        else
          [ ];
      features = (mapFeatures cfg.features false) // (mapFeatures (host.features ++ devboxFeatures) true);
      # Content features this host declared, projected onto the resolved home
      # seam as features.<n>.enable = mkDefault true. mkDefault so the devbox
      # policy can mkForce them off (see home-modules/policy/devbox.nix).
      declaredContentFeatures = builtins.filter (f: builtins.elem f contentFeatures) (
        host.features ++ devboxFeatures
      );
      contentFeaturesModule = {
        features = lib.genAttrs declaredContentFeatures (_: {
          enable = lib.mkDefault true;
        });
      };
      # Resolve declared remotes into topology. Consumers (home ssh config,
      # WezTerm domains) read these resolved remotes; they do not re-derive
      # addresses or the `-mux` convention.
      resolvedRemotes =
        topology.resolveRemotes {
          inherit features;
          sharedDomain = cfg.sharedDomain or "";
        } host.remotes;
    in
    {
      inherit hostKey; # The original key from hosts.nix (e.g., "ash", "spectre")
      inherit (host)
        name
        system
        alias
        u2fKeys
        signingKey
        userSshPublicKey
        enableSwap
        bootLabel
        devbox
        builder
        ;
      inherit features;
      # Resolved remotes (see CONTEXT.md) — the raw host.remotes after topology
      # resolution. This is what modules read as `machine.remotes`.
      remotes = resolvedRemotes;
      nixosModules = [
        bridgeModule
      ];
      darwinModules = [ bridgeModule ];
      homeModules = [
        contentFeaturesModule
      ];
    };
}
