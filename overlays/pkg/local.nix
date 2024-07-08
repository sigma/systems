final: prev: {
  emacs-config = final.callPackage ./local/emacs-config.nix {};

  zsh-config = final.callPackage ./local/zsh-config.nix {};
}
