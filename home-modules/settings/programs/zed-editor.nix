{ pkgs, lib, ... }:
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

    buffer_font_family = "Fira Code";
    buffer_font_fallbacks = [
      "Menlo"
      "Monaco"
      "Courier New"
      "monospace"
    ];
    buffer_font_size = 14;
    buffer_font_features = {
      cv01 = true;
      cv02 = true;
      cv04 = true;
      cv16 = true;
      cv18 = true;
      cv29 = true;
      cv31 = true;
      ss01 = true;
      ss02 = true;
      ss03 = true;
      ss05 = true;
    };

    terminal = {
      font_family = "Fira Code";
      font_fallbacks = [
        "SauceCodePro Nerd Font Mono"
        "Menlo"
        "Monaco"
        "Courier New"
        "monospace"
      ];
      font_size = 13;
      font_weight = 600;
    };
  };
}
