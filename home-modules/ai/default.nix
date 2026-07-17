# Centralized AI agent / model preferences.
#
# Consumers (Zed, claude wrappers, opencode, etc.) read
# `programs.aiProfiles.{agents,editPredictions}` and translate the resolved
# profile to their own settings shape. Each entry references catalog plans
# from `programs.aiCatalog` so vendor identifiers, ACP names, and required
# packages stay in one place.
#
# Local inference is layered: a host selects one backend via
# `programs.aiActiveBackend` (e.g. "omlx" on darwin); this module then
# exposes `programs.aiApis.${api} = endpoint` so consumers can reach the
# active backend by API protocol without naming the backend itself.
#
# As a side effect, this module also:
# - installs `packages` declared by every plan in `aiProfiles.agents`
# - installs the active backend's `packages` (if any)
# - turns on the wrapper module each plan references via `enableModule`
# - asserts that any sops-backed plan's secret is actually declared
{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
with lib;
let
  catalog = import ./catalog.nix { inherit pkgs; };

  authType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "manual"
          "sops"
          "static"
          "none"
        ];
      };
      secret = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  planType = types.submodule {
    options = {
      vendor = mkOption { type = types.str; };
      acp = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      enableModule = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      auth = mkOption {
        type = types.nullOr authType;
        default = null;
      };
    };
  };

  backendType = types.submodule {
    options = {
      api = mkOption { type = types.str; };
      endpoint = mkOption { type = types.str; };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
    };
  };

  modelRefType = types.submodule {
    options = {
      api = mkOption { type = types.str; };
      model = mkOption { type = types.str; };
      promptFormat = mkOption { type = types.str; };
    };
  };

  predictionType = types.submodule {
    options = {
      model = mkOption { type = modelRefType; };
      max_output_tokens = mkOption {
        type = types.int;
        default = 64;
      };
    };
  };

  # Plain attrset types instead of submodules to avoid mutual-recursion in
  # option resolution (lazy enough that the loader can read the catalog while
  # the profiles option is still being defined).
  catalogType = types.attrs;
  profilesType = types.submodule {
    options = {
      agents = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
      };
      editPredictions = mkOption {
        type = types.nullOr types.attrs;
        default = null;
      };
    };
  };

  cfg = config.programs.aiProfiles;

  activeBackend =
    if config.programs.aiActiveBackend != null then
      catalog.backends.${config.programs.aiActiveBackend}
    else
      null;

  enableModules = filter (m: m != null) (map (p: p.enableModule or null) cfg.agents);
in
{
  options.programs.aiCatalog = mkOption {
    type = catalogType;
    default = catalog;
    readOnly = true;
    description = "Available AI plans, backends, and local models.";
  };

  options.programs.aiProfiles = mkOption {
    type = profilesType;
    default = { };
    description = "Named AI profiles consumable by editors and CLI wrappers.";
  };

  options.programs.aiActiveBackend = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = ''
      Name of the local LLM backend running on this host (key into
      `aiCatalog.backends`). Set by the platform feature module that
      provisions the backend (e.g. darwin-modules/features/llm.nix).
    '';
  };

  options.programs.aiApis = mkOption {
    type = types.attrsOf types.str;
    default = { };
    description = ''
      API protocol → endpoint URL, populated from the active backend.
      Consumers read this instead of naming a backend directly.
    '';
  };

  config = mkIf config.features.ai.enable {
    home.packages =
      concatMap (p: p.packages or [ ]) cfg.agents
      ++ optionals (activeBackend != null) (activeBackend.packages or [ ]);

    programs.aiApis = optionalAttrs (activeBackend != null) {
      ${activeBackend.api} = activeBackend.endpoint;
    };

    # Static option paths (not `programs.${m}.enable`) — dynamic keys here
    # confuse home-manager's freeformType resolution and trigger an infinite
    # recursion when other modules read aiProfiles.
    programs.claude-code.enable = mkIf (elem "claude-code" enableModules) true;
    programs.claude-firefly.enable = mkIf (elem "claude-firefly" enableModules) true;
    programs.claude-glm.enable = mkIf (elem "claude-glm" enableModules) true;
    programs.opencode-firefly.enable = mkIf (elem "opencode-firefly" enableModules) true;

    # sops secrets live in the system (darwin/nixos) config; in integrated
    # home-manager `osConfig` is exposed for that. In standalone home-manager
    # there's a sops home-manager module so secrets land under `config.sops`.
    # Skip the check entirely when neither path is available.
    assertions = map (
      plan:
      let
        secret = plan.auth.secret or null;
        knownInSystem = osConfig != null && hasAttrByPath [ "sops" "secrets" secret ] osConfig;
        knownInHome = hasAttrByPath [ "sops" "secrets" secret ] config;
      in
      {
        assertion =
          (plan.auth or null) == null
          || plan.auth.type != "sops"
          || secret == null
          || knownInSystem
          || knownInHome;
        message = "AI plan with sops auth references sops.secrets.${secret} which is not declared.";
      }
    ) cfg.agents;
  };
}
