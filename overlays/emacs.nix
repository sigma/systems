self: super:

{
    emacs = super.emacs.overrideAttrs (oldAttrs: rec {
        patches = oldAttrs.patches ++ [
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-27/fix-window-role.patch";
                sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
            })
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-27/ligatures-freeze-fix.patch";
                sha256 = "41J09/GwQzR48IzgLMqOBry7aUmJSX5RPt2IbpGWjX4=";
            })
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-27/no-frame-refocus-cocoa.patch";
                sha256 = "QLGplGoRpM4qgrIAJIbVJJsa4xj34axwT3LiWt++j/c=";
            })
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-27/system-appearance.patch";
                sha256 = "PNYwPjVA0o7nQFu1jUUc1xkOe6b8dD6oXMH3Vqwy/Cc=";
            })
        ];
    });

    emacsNativeComp = super.emacsNativeComp.overrideAttrs (oldAttrs: rec {
        patches = oldAttrs.patches ++ [
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/fix-window-role.patch";
                sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
            })
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/no-frame-refocus-cocoa.patch";
                sha256 = "QLGplGoRpM4qgrIAJIbVJJsa4xj34axwT3LiWt++j/c=";
            })
            (self.fetchpatch {
                url = "https://github.com/d12frosted/homebrew-emacs-plus/raw/master/patches/emacs-28/system-appearance.patch";
                sha256 = "oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
            })
        ];
    });
}
