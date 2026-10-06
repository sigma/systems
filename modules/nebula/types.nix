{ lib }:
with lib;
rec {
  profile = types.submodule (_: {
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
  });

  user = types.submodule (_: {
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
  });

  host = types.submodule (_: {
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
        description = ''
          Extra ssh_config directives for this host, keyed by upstream
          OpenSSH directive name (e.g. `ForwardAgent`, `IdentityFile`), as
          consumed by `programs.ssh.settings`.
        '';
      };

      u2fKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The U2F authorization keys for PAM authentication";
      };

      signingKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The host's SSH signing *public* key, in `authorized_keys` form. This is
          the identity recorded for this host: every managed host's key is
          collected into `nixConfig.signingKeys` to build the allowed-signers
          list each host verifies against, so record it even when the host signs
          through `signingKeyFile`.
        '';
      };

      signingKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Path to the *private* key this host signs with, enabling agentless
          signing: `ssh-keygen -Y sign` reads the file directly, so git and jj
          sign in contexts that never see an `SSH_AUTH_SOCK` (headless shells,
          devshells, agents). A leading `~/` is expanded against the user's home.

          Leave null when the private half is not a file the host can read — a
          hardware token, say — in which case signing falls back to handing the
          `signingKey` literal to `ssh-keygen`, which then needs an ssh-agent
          holding the match.
        '';
      };

      userSshPublicKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The host's primary user SSH public key, used to authorize logins from this host into devboxes it parents";
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

      devbox = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              hypervisor = mkOption {
                type = types.enum [
                  "tart"
                  "kvm"
                ];
                description = "Hypervisor used to run this devbox";
              };
              guest = mkOption {
                type = types.enum [
                  "linux"
                  "macos"
                ];
                default = "linux";
                description = "Guest OS type";
              };
              parentHost = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Host key of the machine that runs this VM";
              };
              nested = mkOption {
                type = types.bool;
                default = false;
                description = "Enable nested virtualization (requires M3+ Apple Silicon and macOS 15+ for tart)";
              };
              memoryMB = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "VM memory in MB; null leaves tart's default";
              };
              diskGB = mkOption {
                type = types.int;
                default = 50;
                description = "VM disk size in GB at creation time";
              };
            };
          }
        );
        default = null;
        description = "Devbox VM configuration (null means this host is not a devbox)";
      };

      builder = mkOption {
        type = types.nullOr (
          types.submodule {
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
                default = [
                  "nixos-test"
                  "big-parallel"
                ];
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
          }
        );
        default = null;
        description = "Remote builder configuration for this host";
      };
    };
  });
}
// types
