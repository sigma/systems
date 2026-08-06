{
  writeShellApplication,
  cachix,
  gh,
  # Config parameters - must be provided by caller
  # Empty string means "auto-detect at runtime"
  secretsDir ? "",
}:
writeShellApplication {
  name = "bootstrap-cachix";
  runtimeInputs = [
    cachix
    gh
  ];
  meta.description = "Configure cachix authentication using decrypted token matching GitHub handle";
  text = ''
    # Determine secrets directory at runtime
    if [[ -n "${secretsDir}" ]]; then
      SECRETS_DIR="${secretsDir}"
    elif [[ -d /etc/nixos ]] || [[ "$(uname)" == "Darwin" ]]; then
      # NixOS or Darwin: system-level sops
      SECRETS_DIR="/run/secrets"
    else
      # Standalone home-manager on Linux
      SECRETS_DIR="$HOME/.config/sops-nix/secrets"
    fi

    # Get GitHub handle (use argument if provided, otherwise detect via gh)
    if [[ $# -ge 1 ]]; then
      GITHUB_HANDLE="$1"
    else
      echo "Detecting GitHub handle..."
      GITHUB_HANDLE="$(gh api user -q .login)"
    fi

    echo "GitHub handle: $GITHUB_HANDLE"

    TOKEN_FILE="$SECRETS_DIR/cachix/$GITHUB_HANDLE"
    if [[ ! -f "$TOKEN_FILE" ]]; then
      echo "No cachix token found for handle '$GITHUB_HANDLE' at: $TOKEN_FILE"
      echo "Run system-install or home-install first to decrypt secrets"
      exit 1
    fi

    echo "Configuring cachix token for: $GITHUB_HANDLE"
    cachix authtoken "$(cat "$TOKEN_FILE")"

    echo "Done! Cachix authentication configured."
  '';
}
