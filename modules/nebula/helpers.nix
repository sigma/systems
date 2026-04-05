{
  cfg,
  lib,
  ...
}:
let
  # Check if a remote host (raw feature list) has a given feature
  remoteHasFeature = feature: r: builtins.elem feature (r.features or [ ]);

  # Resolve hostname for a remote, using shared domain when both ends have tailscale
  resolveRemote =
    { machine, sharedDomain }:
    r:
    let
      remoteHasTailscale = remoteHasFeature "tailscale" r;
      machineHasTailscale = machine.features.tailscale or false;
      useSharedDomain = machineHasTailscale && remoteHasTailscale && sharedDomain != "";
      hostAlias = if r.alias != null then r.alias else r.name;
    in
    {
      inherit hostAlias;
      remoteIsNixOS = remoteHasFeature "nixos" r;
      hostname = if useSharedDomain then "${hostAlias}.${sharedDomain}" else r.name;
    };

  # Create SSH matchBlock entry for a remote host
  # Takes context about the current machine's features and shared domain
  sshHost =
    { machine, sharedDomain }:
    r:
    let
      resolved = resolveRemote { inherit machine sharedDomain; } r;
      inherit (resolved) hostAlias remoteIsNixOS hostname;
    in
    {
      name = if builtins.isNull r.alias then r.name else r.alias;
      value =
        {
          sendEnv = [ "WINDOW" ];
        }
        // lib.optionalAttrs (r.name != null || hostname != r.name) {
          inherit hostname;
        }
        // lib.optionalAttrs (r.user != null) { user = r.user; }
        // lib.optionalAttrs (r.sshOpts != null) (
          # Merge extraOptions if both sshOpts and NixOS RequestTTY are present
          if remoteIsNixOS && r.sshOpts ? extraOptions then
            r.sshOpts // {
              extraOptions = r.sshOpts.extraOptions // { RequestTTY = "force"; };
            }
          else
            r.sshOpts
        )
        # NixOS hosts need forced TTY because fish hangs without one (ssh -T)
        // lib.optionalAttrs (remoteIsNixOS && (r.sshOpts == null || !(r.sshOpts ? extraOptions))) {
          extraOptions = { RequestTTY = "force"; };
        };
    };

  # Create -mux SSH alias for NixOS hosts (used by WezTerm multiplexing)
  # These bypass RequestTTY=force which breaks WezTerm's mux protocol
  # Must resolve to full hostname since libssh-rs doesn't chain SSH config lookups
  sshMuxAlias =
    { machine, sharedDomain }:
    r:
    let
      resolved = resolveRemote { inherit machine sharedDomain; } r;
    in
    lib.optionalAttrs resolved.remoteIsNixOS {
      "${resolved.hostAlias}-mux" = { hostname = resolved.hostname; };
    };

  # Find a remote by alias suffix (e.g., "devbox" matches "spectre-devbox")
  findRemoteByAliasSuffix =
    remotes: suffix:
    lib.findFirst (r: r.alias != null && lib.hasSuffix suffix r.alias) null remotes;

  # Create an alias matchBlock that points to an existing remote
  mkRemoteAlias =
    remotes: aliasName: suffix:
    let
      remote = findRemoteByAliasSuffix remotes suffix;
      remoteName = if remote.alias != null then remote.alias else remote.name;
    in
    lib.optionalAttrs (remote != null) {
      ${aliasName} = {
        hostname = remoteName;
      };
    };

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
      features = (mapFeatures cfg.features false) // (mapFeatures host.features true);
      # Create a partial machine object for sshHost context
      machineContext = { inherit features; };
      # Create sshHost function with context
      sshHostFn = sshHost {
        machine = machineContext;
        sharedDomain = cfg.sharedDomain or "";
      };
      # Create sshMuxAlias function with same context
      sshMuxAliasFn = sshMuxAlias {
        machine = machineContext;
        sharedDomain = cfg.sharedDomain or "";
      };
    in
    {
      inherit hostKey; # The original key from hosts.nix (e.g., "ash", "spectre")
      inherit (host)
        name
        system
        alias
        u2fKeys
        signingKey
        enableSwap
        bootLabel
        remotes
        builder
        ;
      inherit features;
      nixosModules = [
        bridgeModule
      ];
      darwinModules = [ bridgeModule ];
      homeModules = [
        {
          programs.ssh.matchBlocks =
            builtins.listToAttrs (builtins.map sshHostFn host.remotes)
            // mkRemoteAlias host.remotes "devbox" "-devbox"
            # Add -mux aliases for NixOS hosts (used by WezTerm SSH domains)
            // lib.foldl' (acc: r: acc // sshMuxAliasFn r) { } host.remotes;
        }
      ];
    };
}
