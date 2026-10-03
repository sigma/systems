# claude-glm: Claude Code against Z.AI's GLM API, an endpoint variant of the
# claude-code roster entry (see ./agents.nix). Part of the multi-provider `ai`
# stack (see CONTEXT.md).
{
  config,
  lib,
  osConfig ? null,
  ...
}:
with lib;
let
  cfg = config.programs.claude-glm;
in
{
  options.programs.claude-glm = {
    enable = mkEnableOption "Claude Code with GLM API configuration" // {
      default = config.features.ai.enable;
      defaultText = literalExpression "config.features.ai.enable";
    };

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
  };

  config = mkIf cfg.enable {
    # The key is decrypted by sops: in the system config for integrated
    # home-manager (exposed as osConfig), or by the home sops module in
    # standalone home-manager.
    assertions = [
      {
        assertion =
          (osConfig != null && hasAttrByPath [ "sops" "secrets" cfg.secretName ] osConfig)
          || hasAttrByPath [ "sops" "secrets" cfg.secretName ] config;
        message = "programs.claude-glm needs sops.secrets.${cfg.secretName}, which is not declared.";
      }
    ];

    programs.agents.claude-code.endpoints.glm = {
      description = "Claude Code with GLM API configuration";
      baseUrl = "https://api.z.ai/api/anthropic";
      tokenFile = "${cfg.secretsDir}/${cfg.secretName}";
      timeoutMs = 3000000;
      acp = "glm-acp-agent";
    };
  };
}
