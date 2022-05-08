final: prev:

{
  zinit = prev.zinit.overrideAttrs (oldAttrs: rec {
    version = "main";
    src = final.fetchFromGitHub {
      owner = "zdharma-continuum";
      repo = "zinit";
      rev = "2cdeef387aa39c118cbfdb470f05c184e427ae4c";
      hash = "sha256-8PPZlKWtrQ71k+PXliNxaV7xn/6gqQS3+5nKnNitUtw=";
    };

    installPhase = ''
      outdir="$out/share/$pname"

      cd "$src"

      # Zplugin's source files
      install -dm0755 "$outdir"

      find share -type f -exec install -Dm 755 "{}" "$outdir/{}" \;
      install -m0644 zinit*.zsh "$outdir"
      install -m0644 _zinit "$outdir"
    '';
  });
}
