{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.claude-glm;
  claude-code-pkg = config.programs.claude-code.finalPackage;
in
{
  options.programs.claude-glm = {
    enable = mkEnableOption "Claude Code with GLM API configuration";

    secretsDir = mkOption {
      type = types.str;
      default = "/run/secrets";
      description = "Directory where decrypted secrets are stored";
    };

    secretName = mkOption {
      type = types.str;
      default = "glm-api-key";
      description = "Name of the secret containing the GLM API key";
    };

    baseUrl = mkOption {
      type = types.str;
      default = "https://api.z.ai/api/anthropic";
      description = "Anthropic API base URL";
    };

    timeoutMs = mkOption {
      type = types.str;
      default = "3000000";
      description = "API timeout in milliseconds";
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "The claude-glm wrapper package";
    };
  };

  config = mkIf cfg.enable {
    # Ensure claude-code is enabled when claude-glm is enabled
    programs.claude-code.enable = true;

    programs.claude-glm.package = pkgs.writeShellApplication {
      name = "claude-glm";
      meta.description = "Claude Code with GLM API configuration";
      text = ''
        SECRET_FILE="${cfg.secretsDir}/${cfg.secretName}"
        if [[ ! -f "$SECRET_FILE" ]]; then
          echo "GLM API key not found at: $SECRET_FILE"
          echo "Run system-install first to decrypt secrets"
          exit 1
        fi

        export ANTHROPIC_AUTH_TOKEN
        ANTHROPIC_AUTH_TOKEN=$(cat "$SECRET_FILE")
        export ANTHROPIC_BASE_URL="${cfg.baseUrl}"
        export API_TIMEOUT_MS="${cfg.timeoutMs}"

        exec "${claude-code-pkg}/bin/claude" "$@"
      '';
    };

    home.packages = [ cfg.package ];
  };
}
