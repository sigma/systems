{
  writeShellApplication,
  openssh,
  ssh-to-age,
  sops,
  jq,
  sopsConfigFile ? null,
}:
let
  devbox-keygen = writeShellApplication {
    name = "devbox-keygen";
    runtimeInputs = [
      openssh
      ssh-to-age
      sops
      jq
    ];
    meta.description = "Generate a fresh SSH user key for a devbox and stash it in sops";
    text = ''
      if [[ -z "''${1:-}" ]]; then
        echo "Usage: devbox-keygen <hostname>"
        echo "Example: devbox-keygen ash-devbox"
        exit 1
      fi

      HOST="$1"
      SECRETS_FILE="''${SECRETS_FILE:-secrets/secrets.yaml}"

      if [[ ! -f "$SECRETS_FILE" ]]; then
        echo "Error: secrets file not found at $SECRETS_FILE"
        echo "Run from the flake root, or set SECRETS_FILE."
        exit 1
      fi

      # Make the parent's SSH key available to sops for decryption
      if [[ -z "''${SOPS_AGE_KEY_FILE:-}" && -z "''${SOPS_AGE_KEY:-}" ]]; then
        SSH_KEY="''${SOPS_AGE_SSH_PRIVATE_KEY:-$HOME/.ssh/id_ed25519}"
        if [[ -f "$SSH_KEY" ]]; then
          SOPS_AGE_KEY=$(ssh-to-age -private-key -i "$SSH_KEY")
          export SOPS_AGE_KEY
        fi
      fi

      TMPDIR=$(mktemp -d)
      # shellcheck disable=SC2064
      trap "rm -rf $TMPDIR" EXIT

      echo "==> Generating ed25519 key for $HOST..."
      ssh-keygen -t ed25519 -N "" -C "yann@$HOST" -f "$TMPDIR/id_ed25519" >/dev/null

      AGE_RECIPIENT=$(ssh-to-age < "$TMPDIR/id_ed25519.pub")

      echo "==> Storing private key in sops as devbox-keys/$HOST..."
      KEY_JSON=$(jq -Rs . < "$TMPDIR/id_ed25519")
      ${if sopsConfigFile != null then ''sops --config ${sopsConfigFile}'' else "sops"} \
        --set "[\"devbox-keys\"][\"$HOST\"] $KEY_JSON" "$SECRETS_FILE"

      echo ""
      echo "==> Done. Age recipient for $HOST:"
      echo ""
      echo "    $AGE_RECIPIENT"
      echo ""
      echo "Next steps:"
      echo "  1. Update modules/secrets.nix nebula.secrets.ageKeys with:"
      echo ""
      echo "       {"
      echo "         name = \"yann-$HOST-ssh\";"
      echo "         type = \"ssh\";"
      echo "         publicKey = \"$AGE_RECIPIENT\";"
      echo "       }"
      echo ""
      echo "     (Replace any existing entry with the same name.)"
      echo ""
      echo "  2. Declare the secret in modules/secrets.nix nebula.secrets.secrets:"
      echo ""
      echo "       \"devbox-keys/$HOST\" = systemSecret;"
      echo ""
      echo "  3. Run: devbox-bootstrap $HOST  (then devbox-rebuild $HOST)"
      echo ""
      echo "  devbox-rebuild re-keys secrets/secrets.yaml automatically using"
      echo "  the in-store sops config; no .sops.yaml on disk needed."
    '';
  };
in
{
  inherit devbox-keygen;
}
