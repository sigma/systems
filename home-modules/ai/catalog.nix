# AI catalog: known plans, backends, and local models.
#
# Plans pair a vendor with the bits each consumer needs to wire up: ACP server
# name (for Zed's external-agent registry), CLI packages, optional auth source,
# and an optional reference to an existing wrapper module that already knows
# how to provision the plan (claude-firefly, claude-glm, opencode-firefly).
#
# Backends are local LLM inference servers. Each declares the API protocol it
# speaks (e.g. "openai-compatible") and the endpoint it serves on. A host
# selects at most one via `programs.aiActiveBackend`; consumers then look up
# `programs.aiApis.${api}` and never name the backend directly.
#
# Local models reference an `api` (not a backend) so the same model entry
# works on any host whose active backend speaks that protocol.
{ ... }:
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
      auth = {
        type = "manual";
      };
    };
    google-ai-pro = {
      vendor = "google";
      acp = "gemini";
      # gemini-cli installed via Homebrew (darwin-modules/apps/gemini-cli.nix)
      # rather than nixpkgs, since the nixpkgs version lags behind upstream.
      auth = {
        type = "manual";
      };
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
      auth = {
        type = "static";
      };
    };
    firefly-opencode = {
      vendor = "openai-proxy";
      acp = null;
      enableModule = "opencode-firefly";
      auth = {
        type = "static";
      };
    };
  };

  backends = {
    # Apple Silicon, MLX-based. Installed via Homebrew (formula + DMG menu-bar
    # app); see darwin-modules/features/llm.nix.
    omlx = {
      api = "openai-compatible";
      endpoint = "http://localhost:8000";
    };
  };

  localModels = {
    # Zed's open-weights edit-prediction model. Fetch into the omlx model dir
    # (default: ~/.omlx/models) from
    # https://huggingface.co/zed-industries/zeta-2.1 — you may need an
    # MLX-converted variant (mlx-community/zeta-2.1-* or `mlx_lm.convert`).
    zeta = {
      api = "openai-compatible";
      model = "zeta-2.1";
      promptFormat = "zeta2_1";
    };
  };
}
