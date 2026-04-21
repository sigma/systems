{ config, pkgs, ... }:
let
  parentDir = config.programs.emacs.chemacs.defaultUserParentDir;
  vanillaDir = "${parentDir}/vanilla";
in
{
  enable = true;

  vanilla.enable = true;

  # Packages available to all Emacs profiles (vanilla uses these via Nix)
  extraPackages = epkgs: with epkgs; [
    # ui
    doom-themes
    doom-modeline
    nerd-icons
    hl-todo
    diff-hl
    which-key
    # completion
    vertico
    vertico-posframe
    marginalia
    orderless
    consult
    embark
    nerd-icons-completion
    corfu
    cape
    # editing
    multiple-cursors
    tempel
    apheleia
    vundo
    smartparens
    envrc
    editorconfig
    # tools
    magit
    eros
    nerd-icons-dired
    # window
    ace-window
    olivetti
    # org
    org-roam
    org-roam-ui
    websocket
    vulpea
    org-super-agenda
    doct
    ox-gfm
    ox-hugo
    language-detection
    citar
    citar-org-roam
    # languages
    go-mode
    rust-mode
    nix-mode
    yaml-mode
    lua-mode
    markdown-mode
    auctex
    d2-mode
    # mail
    notmuch
  ];

  chemacs.profiles = {
    default = {
      userDir = vanillaDir;
    };

    vanilla = {
      userDir = vanillaDir;
    };
  };
}
