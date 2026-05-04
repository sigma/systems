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

  ai = config.programs.aiProfiles;
  zedAgents = lib.filter (p: p.acp != null) ai.agents;

  # Devboxes whose parent is this host — surfaced to Zed as ssh_connections
  # so the editor can open remote workspaces against them.
  myDevboxes = lib.filterAttrs (_: b: b.parentHost == machine.hostKey) (
    nixConfig.builders or { }
  );
  devboxSshConnections = lib.mapAttrsToList (name: b: {
    host = if b.alias != null then b.alias else b.name;
    projects = [ ];
  }) myDevboxes;
in
{
  enable = true;
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

    agent_servers = lib.listToAttrs (
      map (p: {
        name = p.acp;
        value = {
          type = "registry";
        };
      }) zedAgents
    );

    ssh_connections = devboxSshConnections;
  }
  // lib.optionalAttrs (ai.editPredictions != null) {
    edit_predictions =
      let
        ep = ai.editPredictions;
      in
      {
        provider = ep.model.provider;
        ${ep.model.provider} = {
          model = ep.model.model;
          max_output_tokens = ep.max_output_tokens;
        };
      };
  };
}
