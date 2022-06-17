final: prev:

{
  zinit = prev.zinit.overrideAttrs (oldAttrs: rec {
    version = "main";
    src = final.fetchFromGitHub {
      owner = "zdharma-continuum";
      repo = "zinit";
      rev = "161d7c1ee1fc2bbb43442cd90b48e502bf62603f";
      hash = "sha256-XJjlinLkXmvmayGeFxJhHSFUHrf18E7J+TreQdGb5GY=";
    };

    installPhase = ''
      outdir="$out/share/$pname"

      cd "$src"

      # zinit's source files
      install -dm0755 "$outdir"

      find share -type f -exec install -Dm 755 "{}" "$outdir/{}" \;
      install -m0644 zinit*.zsh "$outdir"
      install -m0644 _zinit "$outdir"

      # disable self-update
      sed -i -e '/^.zinit-self-update.*/a\
      +zinit-message "Zinit is Nix-managed, skipping self-update"; return 0;' "$outdir/zinit-autoload.zsh"
    '';
  });
}
