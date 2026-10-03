{
  config,
  pkgs,
  lib,
  machine,
  nixConfig,
  ...
}:
let
  # Wrap `zed` (the real binary) and point `zeditor` at it so both invocations
  # see the same PATH. We bypass the home-manager module's `extraPackages`
  # because it wraps `zeditor` only, leaving `zed` unwrapped.
  extras = [
    pkgs.direnv
    pkgs.fish-lsp
    pkgs.gopls
    pkgs.jsonnet-language-server
    pkgs.just-lsp
    pkgs.lua-language-server
    pkgs.nixd
    pkgs.rust-analyzer
    pkgs.starpls
  ];

  wrapped = pkgs.symlinkJoin {
    name = "${lib.getName pkgs.zed-editor}-wrapped-${lib.getVersion pkgs.zed-editor}";
    paths = [ pkgs.zed-editor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/zed --suffix PATH : ${lib.makeBinPath extras}
      ln -sf zed $out/bin/zeditor
    '';
  };

  profiles = config.programs.fontProfiles;
  fbName = f: if lib.isString f then f else f.family;
  fallbackNames = p: map fbName p.fallbacks;

  # External agents: every enabled roster agent with an ACP id, plus the GLM
  # endpoint. Zed fetches them from its registry, so they need not be
  # installed here.
  acpAgents =
    lib.pipe config.programs.agents [
      (lib.filterAttrs (_: a: a.enable && a.acp != null))
      (lib.mapAttrsToList (_: a: a.acp))
    ]
    ++ lib.optional config.programs.claude-glm.enable config.programs.claude-glm.acp;

  # Edit predictions from the local LLM server, when the machine runs one.
  # The model id is whatever LM Studio's /v1/models reports once loaded
  # (`curl -s localhost:1234/v1/models | jq`); fetch a GGUF build via its
  # Discover tab.
  predictionApi = config.programs.aiApis.openai-compatible or null;

  # Devboxes whose parent is this host — surfaced to Zed as ssh_connections
  # so the editor can open remote workspaces against them.
  myDevboxes = lib.filterAttrs (_: b: b.parentHost == machine.hostKey) (nixConfig.builders or { });
  devboxSshConnections = lib.mapAttrsToList (name: b: {
    host = if b.alias != null then b.alias else b.name;
    projects = [ ];
  }) myDevboxes;
in
{
  enable = false;
  package = wrapped;
  extensions = [
    "catppuccin-icons"
    "elisp"
    "fish"
    "git-firefly"
    "jsonnet"
    "justfile"
    "lua"
    "nix"
    "starlark"
  ];

  userSettings = {
    languages.Nix.language_servers = [
      "nixd"
      "!nil"
    ];

    telemetry = {
      diagnostics = false;
      metrics = false;
    };

    # Experimental Zed features. Opt in via discussion #25936.
    feature_flags = {
      notebooks = "on";
      "tabular-data-preview" = "on";
    };

    cli_default_open_behavior = "new_window";
    base_keymap = "Emacs";

    project_panel.dock = "right";
    outline_panel.dock = "right";
    collaboration_panel.dock = "right";
    git_panel.dock = "right";
    agent = {
      dock = "left";
      favorite_models = [ ];
      model_parameters = [ ];
    };

    buffer_font_family = profiles.editor.family.family;
    buffer_font_fallbacks = fallbackNames profiles.editor;
    buffer_font_size = profiles.editor.size;
    buffer_font_features = lib.genAttrs profiles.editor.features (_: true);

    ui_font_family = profiles.ui.family.family;
    ui_font_fallbacks = fallbackNames profiles.ui;
    ui_font_size = profiles.ui.size;

    terminal = {
      font_family = profiles.terminal.family.family;
      font_fallbacks = fallbackNames profiles.terminal;
      font_size = profiles.terminal.size;
      font_weight = profiles.terminal.weight;
    };

    agent_servers = lib.genAttrs acpAgents (_: {
      type = "registry";
    });

    ssh_connections = devboxSshConnections;
  }
  // lib.optionalAttrs (predictionApi != null) {
    edit_predictions = {
      provider = "open_ai_compatible_api";
      open_ai_compatible_api = {
        api_url = "${predictionApi}/v1/completions";
        model = "google/gemma-4-e4b";
        prompt_format = "infer";
        max_output_tokens = 64;
      };
    };
  };
}
