{
  writeShellApplication,
  gh,
  # Config parameters - must be provided by caller
  secretsDir ? "/run/secrets",
}:
writeShellApplication {
  name = "bootstrap-github";
  runtimeInputs = [ gh ];
  meta.description = "Upload machine SSH key to GitHub using decrypted PAT (requires sudo)";
  text = ''
    PAT_FILE="${secretsDir}/github-key-uploader-pat"
    if [[ ! -f "$PAT_FILE" ]]; then
      echo "GitHub PAT not found at: $PAT_FILE"
      echo "Run system-install or home-install first to decrypt secrets"
      exit 1
    fi

    SSH_KEY="''${1:-$HOME/.ssh/id_ed25519.pub}"
    if [[ ! -f "$SSH_KEY" ]]; then
      echo "SSH public key not found: $SSH_KEY"
      exit 1
    fi

    echo "Authenticating with GitHub..."
    gh auth login --with-token < "$PAT_FILE"

    echo "Uploading SSH key: $SSH_KEY"
    gh ssh-key add "$SSH_KEY" --title "$(hostname -s)-$(date +%Y%m%d)"

    echo "Done! You can now use: gh auth setup-git"
  '';
}
