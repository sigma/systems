{
  stdenv,
  nix-filter,
  coreutils,
  findutils,
  emacs,
  lib,
  user ? null,
}:
stdenv.mkDerivation {
  pname = "emacs-config";
  version = "dev";
  src = nix-filter {
    root = ./emacs-config;
    include = [
      "emacs.org"
    ];
  };

  buildInputs = [emacs coreutils];
  buildPhase =
    (lib.optionalString (user != null) ''
      cat <<EOF > +id.el
      (setq user-full-name "${user.name}"
        user-mail-address "${user.email}")
      EOF
    '')
    + ''
      # Tangle org files
      ${coreutils}/bin/cp $src/emacs.org .
      ${emacs}/bin/emacs --batch -Q \
        -l org \
        emacs.org \
        -f org-babel-tangle
    '';

  dontUnpack = true;

  installPhase = ''
    ${findutils}/bin/find . -name "*.el" -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
