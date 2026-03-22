{
  lib,
  stdenv,
  coreutils,
  findutils,
  gnused,
  emacs,
  user ? null,
}:
stdenv.mkDerivation {
  pname = "emacs-vanilla-config";
  version = "dev";
  src = lib.fileset.toSource {
    root = ./emacs-config;
    fileset = lib.fileset.unions [
      ./emacs-config/vanilla.org
      ./emacs-config/common.org
    ];
  };

  buildInputs = [
    emacs
    coreutils
  ];
  buildPhase =
    (lib.optionalString (user != null) ''
      cat <<EOF > +id.el
      (setq user-full-name "${user.name}"
        user-mail-address "${user.email}")
      EOF
    '')
    + ''
      # Copy org files and append common.org blocks for noweb resolution
      ${coreutils}/bin/cp $src/vanilla.org $src/common.org .
      ${coreutils}/bin/chmod u+w vanilla.org
      # Append common.org headings (named blocks) for noweb references
      ${gnused}/bin/sed -n '/^\*/,$p' common.org >> vanilla.org
      ${emacs}/bin/emacs --batch -Q \
        -l org \
        vanilla.org \
        -f org-babel-tangle
    '';

  dontUnpack = true;

  installPhase = ''
    ${findutils}/bin/find . -name "*.el" -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
