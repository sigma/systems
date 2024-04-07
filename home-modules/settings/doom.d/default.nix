{
  pkgs,
  user,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "emacs-config";
  version = "dev";
  src = pkgs.nix-filter {
    root = ./.;
    include = [
      "emacs.org"
    ];
  };

  buildInputs = [pkgs.emacs pkgs.coreutils];
  buildPhase = ''
    cat <<EOF > +id.el
    (setq user-full-name "${user.name}"
      user-mail-address "${user.email}")
    EOF

    # Tangle org files
    cp $src/emacs.org .
    emacs --batch -Q \
      -l org \
      emacs.org \
      -f org-babel-tangle
  '';

  dontUnpack = true;

  installPhase = ''
    find . -name "*.el" -exec install -vDm 755 {} $out/{} \;
  '';
}
