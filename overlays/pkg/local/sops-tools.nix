{
  writeShellApplication,
  sops,
  ssh-to-age,
  age-plugin-yubikey,
  # Config parameters - must be provided by caller
  sopsConfigFile ? null,
}:
let
  # sops-config: Show generated SOPS configuration
  sops-config = writeShellApplication {
    name = "sops-config";
    meta.description = "Show SOPS configuration (generated from Nix)";
    text = ''
      echo "# Generated SOPS configuration"
      echo "# To update .sops.yaml: sops-config > .sops.yaml"
      echo ""
      cat ${sopsConfigFile}
    '';
  };

  # sops-edit: Edit encrypted secrets file
  sops-edit = writeShellApplication {
    name = "sops-edit";
    runtimeInputs = [ sops ssh-to-age ];
    meta.description = "Edit encrypted secrets file (creates if missing)";
    text = ''
      FILE="''${1:-secrets/secrets.yaml}"
      if [[ ! -f "$FILE" ]]; then
        echo "Creating new secrets file: $FILE"
        mkdir -p "$(dirname "$FILE")"
      fi
      # Use SSH key for age decryption if no age key file is set
      if [[ -z "''${SOPS_AGE_KEY_FILE:-}" && -z "''${SOPS_AGE_KEY:-}" ]]; then
        SSH_KEY="''${SOPS_AGE_SSH_PRIVATE_KEY:-$HOME/.ssh/id_ed25519}"
        if [[ -f "$SSH_KEY" ]]; then
          SOPS_AGE_KEY=$(ssh-to-age -private-key -i "$SSH_KEY")
          export SOPS_AGE_KEY
        fi
      fi

      # Run the editor
      sops --config ${sopsConfigFile} "$FILE" || true

      # Always update keys (idempotent - re-encrypts for any new keys in config)
      sops --config ${sopsConfigFile} updatekeys -y "$FILE"
    '';
  };

  # sops-key: Show age public key from SSH or YubiKey
  sops-key = writeShellApplication {
    name = "sops-key";
    runtimeInputs = [ ssh-to-age age-plugin-yubikey ];
    meta.description = "Show age public key (-t ssh|yubikey, default: ssh)";
    text = ''
      TYPE="ssh"
      while getopts "t:" opt; do
        case $opt in
          t) TYPE="$OPTARG" ;;
          *) echo "Usage: sops-key [-t ssh|yubikey] [path/to/ssh/key]"; exit 1 ;;
        esac
      done
      shift $((OPTIND-1))

      case "$TYPE" in
        ssh)
          SSH_KEY="''${1:-$HOME/.ssh/id_ed25519}"
          if [[ ! -f "$SSH_KEY" ]]; then
            echo "SSH key not found: $SSH_KEY"
            echo "Usage: sops-key [-t ssh] [path/to/ssh/key]"
            exit 1
          fi
          echo "# Age public key for: $SSH_KEY"
          ssh-to-age -i "$SSH_KEY.pub" 2>/dev/null || \
          ssh-to-age < "$SSH_KEY.pub"
          ;;
        yubikey)
          echo "# Age public key from YubiKey"
          age-plugin-yubikey --identity
          ;;
        *)
          echo "Unknown key type: $TYPE"
          echo "Usage: sops-key [-t ssh|yubikey]"
          exit 1
          ;;
      esac
    '';
  };
in
{
  inherit sops-config sops-edit sops-key;

  # Convenience: all tools as a list
  all = [ sops-config sops-edit sops-key ];
}
