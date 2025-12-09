{
  writeShellApplication,
  # Config parameters - must be provided by caller
  secretsDir ? "/run/secrets",
}:
writeShellApplication {
  name = "claude-glm";
  meta.description = "Claude Code with GLM API configuration";
  text = ''
    SECRET_FILE="${secretsDir}/glm-api-key"
    if [[ ! -f "$SECRET_FILE" ]]; then
      echo "GLM API key not found at: $SECRET_FILE"
      echo "Run system-install first to decrypt secrets"
      exit 1
    fi

    export ANTHROPIC_AUTH_TOKEN
    ANTHROPIC_AUTH_TOKEN=$(cat "$SECRET_FILE")
    export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
    export API_TIMEOUT_MS="3000000"

    # Use homebrew-installed claude
    CLAUDE_BIN="/opt/homebrew/bin/claude"
    if [[ ! -x "$CLAUDE_BIN" ]]; then
      CLAUDE_BIN="$(command -v claude)"
    fi

    exec "$CLAUDE_BIN" "$@"
  '';
}
