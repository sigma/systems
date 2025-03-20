final: prev: let
  icon = final.fetchurl {
    url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/icons/modern-black-dragon.icns";
    hash = "sha256-rUOBImaeVtsR19ZusGuZnm/A8IY1GCIWZn+E7/cASEY=";
  };
  emacs30Patches = [
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/fix-window-role.patch";
      sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-30/system-appearance.patch";
      sha256 = "sha256-3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-30/poll.patch";
      sha256 = "sha256-bQW9LPmJhMAtP2rftndTdjw0uipPyOp5oXqtIcs7i/Q=";
    })
    (final.fetchpatch {
      url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-30/round-undecorated-frame.patch";
      sha256 = "sha256-uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
    })
  ];
  iconPhase = ''
    ${final.coreutils}/bin/cp -f ${icon} nextstep/Cocoa/Emacs.base/Contents/Resources/Emacs.icns
  '';
in {
  emacs = prev.emacs30;

  emacs-git = prev.emacs-git.overrideAttrs (oldAttrs: {
    postPatch = oldAttrs.postPatch + iconPhase;
    patches = oldAttrs.patches ++ emacs30Patches;
  });
}
