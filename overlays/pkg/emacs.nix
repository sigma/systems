final: prev: let
  emacs28Patches = [
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/fix-window-role.patch";
      sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/no-frame-refocus-cocoa.patch";
      sha256 = "QLGplGoRpM4qgrIAJIbVJJsa4xj34axwT3LiWt++j/c=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/system-appearance.patch";
      sha256 = "oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
    })
  ];
  emacs29Patches = [
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-29/fix-window-role.patch";
      sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-29/no-frame-refocus-cocoa.patch";
      sha256 = "QLGplGoRpM4qgrIAJIbVJJsa4xj34axwT3LiWt++j/c=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-29/system-appearance.patch";
      sha256 = "oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-29/poll.patch";
      sha256 = "jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-29/round-undecorated-frame.patch";
      sha256 = "qPenMhtRGtL9a0BvGnPF4G1+2AJ1Qylgn/lUM8J2CVI=";
    })
  ];
in {
  emacs = final.emacs-unstable;

  emacs-unstable = prev.emacs-unstable.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ emacs28Patches;
  });

  emacsGit = prev.emacsGit.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ emacs29Patches;
  });

  emacsConfigFor = {
    user,
    emacs ? final.emacs,
  }:
    final.stdenv.mkDerivation {
      pname = "emacs-config";
      version = "dev";
      src = final.nix-filter {
        root = ./emacs-config;
        include = [
          "emacs.org"
        ];
      };

      buildInputs = [final.emacs final.coreutils];
      buildPhase = ''
        cat <<EOF > +id.el
        (setq user-full-name "${user.name}"
          user-mail-address "${user.email}")
        EOF

        # Tangle org files
        ${final.coreutils}/bin/cp $src/emacs.org .
        ${emacs}/bin/emacs --batch -Q \
          -l org \
          emacs.org \
          -f org-babel-tangle
      '';

      dontUnpack = true;

      installPhase = ''
        ${final.findutils}/bin/find . -name "*.el" -exec ${final.coreutils}/bin/install -vDm 755 {} $out/{} \;
      '';
    };
}
