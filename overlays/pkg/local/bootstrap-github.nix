{
  writeShellApplication,
  gh,
  # Config parameters - must be provided by caller
  # Empty string means "auto-detect at runtime"
  secretsDir ? "",
}:
writeShellApplication {
  name = "bootstrap-github";
  runtimeInputs = [ gh ];
  meta.description = "Upload machine SSH key to GitHub using decrypted PAT";
  text = ''
    # Determine the real user's home directory (handle running under sudo)
    if [[ -n "''${SUDO_USER:-}" ]]; then
      REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
      REAL_HOME="$HOME"
    fi

    # Determine secrets directory at runtime
    if [[ -n "${secretsDir}" ]]; then
      SECRETS_DIR="${secretsDir}"
    elif [[ -d /etc/nixos ]] || [[ "$(uname)" == "Darwin" ]]; then
      # NixOS or Darwin: system-level sops
      SECRETS_DIR="/run/secrets"
    else
      # Standalone home-manager on Linux
      SECRETS_DIR="$REAL_HOME/.config/sops-nix/secrets"
    fi

    PAT_FILE="$SECRETS_DIR/github-key-uploader-pat"
    if [[ ! -f "$PAT_FILE" ]]; then
      echo "GitHub PAT not found at: $PAT_FILE"
      echo "Run system-install or home-install first to decrypt secrets"
      exit 1
    fi

    # Read the PAT - use sudo if not readable directly
    if [[ -r "$PAT_FILE" ]]; then
      PAT=$(cat "$PAT_FILE")
    else
      echo "Reading PAT with sudo..."
      PAT=$(sudo cat "$PAT_FILE")
    fi

    SSH_KEY="''${1:-$REAL_HOME/.ssh/id_ed25519.pub}"
    if [[ ! -f "$SSH_KEY" ]]; then
      echo "SSH public key not found: $SSH_KEY"
      exit 1
    fi

    echo "Uploading SSH key: $SSH_KEY"
    # Use GH_TOKEN env var to authenticate without writing to config
    GH_TOKEN="$PAT" gh ssh-key add "$SSH_KEY" --title "$(hostname -s)-$(date +%Y%m%d)"

    echo "Done! SSH key uploaded to GitHub."
  '';
}
