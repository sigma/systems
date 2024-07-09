{
  pkgs,
  nix-filter ? pkgs.nix-filter,
}: {
  emacs-config = pkgs.callPackage ./emacs-config.nix {
    inherit nix-filter;
  };

  zsh-config = pkgs.callPackage ./zsh-config.nix {
    inherit nix-filter;
  };
}
