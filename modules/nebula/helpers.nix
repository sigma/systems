{
  cfg,
  lib,
  ...
}:
let
  # Create SSH matchBlock entry for a remote host
  # Takes context about the current machine's features and shared domain
  sshHost =
    { machine, sharedDomain }:
    r:
    let
      # Check if remote has tailscale feature (it's a list in host definition)
      remoteHasTailscale = builtins.elem "tailscale" (r.features or [ ]);
      # Check if current machine has tailscale (processed attrset)
      machineHasTailscale = machine.features.tailscale or false;
      # Use shared domain DNS if both have tailscale
      useSharedDomain = machineHasTailscale && remoteHasTailscale && sharedDomain != "";
      # Determine hostname
      hostAlias = if r.alias != null then r.alias else r.name;
      sharedHostname = "${hostAlias}.${sharedDomain}";
      regularHostname = r.name;
    in
    {
      name = if builtins.isNull r.alias then r.name else r.alias;
      value =
        {
          sendEnv = [ "WINDOW" ];
        }
        // lib.optionalAttrs (r.name != null || useSharedDomain) {
          hostname = if useSharedDomain then sharedHostname else regularHostname;
        }
        // lib.optionalAttrs (r.user != null) { user = r.user; }
        // lib.optionalAttrs (r.sshOpts != null) r.sshOpts;
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
            // mkRemoteAlias host.remotes "devbox" "-devbox";
        }
      ];
    };
}
