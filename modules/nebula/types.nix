{ lib }:
with lib;
rec {
  profile = types.submodule (
    { ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the profile";
        };

        emails = mkOption {
          type = types.listOf types.str;
          description = "The emails of the profile";
        };
      };
    }
  );

  user = types.submodule (
    { ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the user";
        };

        githubHandle = mkOption {
          type = types.str;
          description = "The github handle of the user";
        };

        login = mkOption {
          type = types.str;
          description = "The login of the user";
        };

        profiles = mkOption {
          type = types.listOf profile;
          default = [ ];
          description = "The profiles of the user";
        };
      };
    }
  );

  host = types.submodule (
    { ... }:
    {
      options = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The name of the host";
        };

        system = mkOption {
          type = types.str;
          description = "The system of the host";
        };

        alias = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The alias of the host";
        };

        features = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "The features of the host";
        };

        user = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The user of the host";
        };

        homeRoot = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The home root of the host";
        };

        sshOpts = mkOption {
          type = types.nullOr types.attrs;
          default = null;
          description = "The ssh options of the host";
        };

        u2fKeys = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "The U2F authorization keys for PAM authentication";
        };

        signingKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The SSH signing key for git commits";
        };

        remotes = mkOption {
          type = types.listOf host;
          default = [ ];
          description = "The remotes of the host";
        };

        enableSwap = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable swap on the host";
        };

        bootLabel = mkOption {
          type = types.str;
          default = "ESP";
          description = "The label of the boot partition";
        };

        builder = mkOption {
          type = types.nullOr (types.submodule {
            options = {
              enable = mkEnableOption "this host as a remote builder";
              maxJobs = mkOption {
                type = types.int;
                default = 4;
                description = "Maximum number of parallel build jobs";
              };
              speedFactor = mkOption {
                type = types.int;
                default = 1;
                description = "Speed factor relative to other builders (higher = preferred)";
              };
              supportedFeatures = mkOption {
                type = types.listOf types.str;
                default = [ "nixos-test" "big-parallel" ];
                description = "Supported build features";
              };
              publicHostKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "SSH host key for verification (prevents MITM)";
              };
              sshUser = mkOption {
                type = types.str;
                default = "nixbuilder";
                description = "SSH user for builder connections";
              };
              sshPublicKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "SSH public key for authorized_keys on this builder";
              };
              storePublicKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Store signing public key for this builder";
              };
            };
          });
          default = null;
          description = "Remote builder configuration for this host";
        };
      };
    }
  );
}
// types
