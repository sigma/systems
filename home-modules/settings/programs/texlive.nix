{ ... }:
{
  enable = true;

  extraPackages = (
    texpkgs: {
      inherit (texpkgs)
        scheme-basic
        dvisvgm
        dvipng # for preview and export as html
        wrapfig
        amsmath
        ulem
        hyperref
        capt-of
        ;
    }
  );
}
