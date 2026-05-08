# AI catalog: known plans, providers, and local models.
#
# Plans pair a vendor with the bits each consumer needs to wire up: ACP server
# name (for Zed's external-agent registry), CLI packages, optional auth source,
# and an optional reference to an existing wrapper module that already knows
# how to provision the plan (claude-firefly, claude-glm, opencode-firefly).
{ pkgs, ... }:
{
  plans = {
    # Personal subscriptions
    claude-max = {
      vendor = "anthropic";
      acp = "claude-acp";
      # claude-code is installed via programs.claude-code (set below), not
      # listed here, to avoid a buildEnv conflict with the existing wrappers
      # that already enable that module.
      enableModule = "claude-code";
      auth = { type = "manual"; };
    };
    google-ai-pro = {
      vendor = "google";
      acp = "gemini";
      # gemini-cli installed via Homebrew (darwin-modules/apps/gemini-cli.nix)
      # rather than nixpkgs, since the nixpkgs version lags behind upstream.
      auth = { type = "manual"; };
    };
    z-ai-coding = {
      vendor = "z-ai";
      acp = "glm-acp-agent";
      enableModule = "claude-glm";
      auth = {
        type = "sops";
        secret = "glm-api-key";
      };
    };

    # Work (Firefly Tailscale proxy). Not exposed in Zed.
    firefly-claude = {
      vendor = "anthropic-proxy";
      acp = null;
      enableModule = "claude-firefly";
      auth = { type = "static"; };
    };
    firefly-opencode = {
      vendor = "openai-proxy";
      acp = null;
      enableModule = "opencode-firefly";
      auth = { type = "static"; };
    };
  };

  providers = {
    ollama = {
      packages = [ pkgs.ollama ];
      endpoint = "http://localhost:11434";
    };
  };

  localModels = {
    gemma4-26b = {
      provider = "ollama";
      model = "gemma4:26b";
    };
    gemma4-31b-coding = {
      provider = "ollama";
      model = "gemma4:31b-coding-mtp-bf16";
    };
    qwen3-coder = {
      provider = "ollama";
      model = "qwen3-coder-next:latest";
    };
  };
}
