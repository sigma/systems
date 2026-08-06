# Distributed builds configuration
# This module configures nix.buildMachines for remote builds
# and sets up substituters for using remote stores as caches.
{
  config,
  lib,
  machine,
  nixConfig,
  ...
}:
with lib;
let
  # Get all builders EXCEPT the current machine
  otherBuilders = filterAttrs
    (name: b: b.name != machine.name)
    nixConfig.builders;

  # Generate buildMachines entries
  buildMachines = mapAttrsToList (name: b: {
    hostName = if b.alias != null then b.alias else b.name;
    systems = [ b.system ];
    maxJobs = b.maxJobs;
    speedFactor = b.speedFactor;
    supportedFeatures = b.supportedFeatures;
    sshUser = b.sshUser;
    sshKey = config.sops.secrets."builder-keys/${name}".path;
  } // optionalAttrs (b.publicHostKey != null) {
    publicHostKey = b.publicHostKey;
  }) otherBuilders;

  # Generate substituters list (ssh-ng:// URLs)
  substituters = mapAttrsToList
    (name: b: "ssh-ng://${b.sshUser}@${if b.alias != null then b.alias else b.name}")
    otherBuilders;

  # Check if we have any builders configured
  hasBuilders = nixConfig.builders != { };
in
{
  config = mkIf hasBuilders {
    # Declare sops secrets for builder SSH keys (to connect TO other builders)
    sops.secrets = mapAttrs' (name: b: {
      name = "builder-keys/${name}";
      value = { mode = "0400"; };
    }) otherBuilders;

    nix.buildMachines = buildMachines;
    nix.distributedBuilds = true;

    # Add builders as extra substituters
    nix.settings.extra-substituters = substituters;
  };
}
