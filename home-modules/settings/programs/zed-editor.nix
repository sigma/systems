{
  config,
  pkgs,
  lib,
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
  };
}
