final: prev: {
  procmail = prev.procmail.overrideAttrs (newAttrs: oldAttrs: {
    postPatch = final.lib.concatStrings [
      ''
        sed -i Makefile \
          -e "s%^CFLAGS0 =%CFLAGS0 = -std=c89%"
      ''
      (oldAttrs.postPatch or "")
    ];
  });
}
