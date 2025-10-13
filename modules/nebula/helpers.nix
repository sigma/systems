{
  cfg,
  lib,
  ...
}:
let
  sshHost = r: {
    name = if builtins.isNull r.alias then r.name else r.alias;
    value = {
      sendEnv = [ "WINDOW" ];
    }
    // lib.optionalAttrs (r.name != null) {
      hostname = r.name;
    }
    // lib.optionalAttrs (r.user != null) {
      user = r.user;
    }
    // lib.optionalAttrs (r.sshOpts != null) r.sshOpts;
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
    host:
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
    in
    {
      inherit (host)
        name
        system
        alias
        u2fKeys
        signingKey
        ;
      inherit features;
      nixosModules = [
        bridgeModule
      ];
      darwinModules = [ bridgeModule ];
      homeModules = [
        {
          programs.ssh.matchBlocks = builtins.listToAttrs (builtins.map sshHost host.remotes);
        }
      ];
    };
}
