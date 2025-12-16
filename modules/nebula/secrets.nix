{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nebula.secrets;

  # Type for an age key
  ageKeyType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Identifier for this key (used in .sops.yaml anchors)";
      };
      publicKey = mkOption {
        type = types.str;
        description = "Age public key (age1...) or SSH public key";
      };
      type = mkOption {
        type = types.enum [ "ssh" "age" "yubikey" ];
        default = "age";
        description = "Type of key (for documentation purposes)";
      };
    };
  };

  # Generate .sops.yaml content from defined keys
  sopsConfigText =
    let
      keyAnchors = concatMapStringsSep "\n" (key: "  - &${key.name} ${key.publicKey}") cfg.ageKeys;
      keyRefs = concatMapStringsSep "\n" (key: "          - *${key.name}") cfg.ageKeys;
    in
    ''
      # Generated from Nix - do not edit manually
      # Regenerate with: sops-config (in devshell)
      keys:
      ${keyAnchors}

      creation_rules:
        - path_regex: secrets/.*\.(yaml|json)$
          key_groups:
            - age:
      ${keyRefs}
    '';
in
{
  options.nebula.secrets = {
    enable = mkEnableOption "secrets management with sops-nix";

    ageKeys = mkOption {
      type = types.listOf ageKeyType;
      default = [ ];
      description = "Age keys that can decrypt secrets";
      example = literalExpression ''
        [
          {
            name = "admin-ssh";
            type = "ssh";
            publicKey = "age1xxxxxxxxx...";
          }
        ]
      '';
    };

    defaultSopsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Default SOPS-encrypted secrets file. Set to null to skip sops configuration until secrets exist.";
    };

    sshKeyPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH key paths to try for decryption (relative to home or absolute)";
      example = [ "~/.ssh/id_ed25519" ];
    };

    ageKeyFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to age key file for decryption";
    };

    secrets = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          sopsFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Override sopsFile for this secret";
          };
          owner = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Owner of the secret file (system secrets only)";
          };
          group = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Group of the secret file (system secrets only)";
          };
          mode = mkOption {
            type = types.str;
            default = "0400";
            description = "File mode for the secret";
          };
        };
      });
      default = { };
      description = "Secrets to decrypt";
      example = literalExpression ''
        {
          github-pat = { };
          api-key = { mode = "0440"; };
        }
      '';
    };

    _sopsConfigText = mkOption {
      type = types.str;
      internal = true;
      default = "# Secrets management not enabled";
      description = "Generated SOPS configuration text (internal use)";
    };
  };

  config = {
    nebula.secrets._sopsConfigText = mkIf cfg.enable sopsConfigText;
  };
}
