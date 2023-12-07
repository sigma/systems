final: prev: {
  zinit = prev.zinit.overrideAttrs (oldAttrs: rec {
    version = "v3.12.1";
    src = final.fetchFromGitHub {
      owner = "zdharma-continuum";
      repo = "zinit";
      rev = version;
      hash = "sha256-REd997dop9gAosG4QkEKIc3jYIRLeB3MYBPiYMlDGUs=";
    };

    installPhase = ''
      outdir="$out/share/$pname"

      cd "$src"

      # zinit's source files
      install -dm0755 "$outdir"

      find share -type f -exec install -Dm 755 "{}" "$outdir/{}" \;
      install -m0644 zinit*.zsh "$outdir"
      install -m0644 _zinit "$outdir"

      # zinit's documentation
      install -dm0755 "$outdir/doc"
      install -m0644 doc/zinit.1 "$outdir/doc"

      # disable self-update
      sed -i -e '/^.zinit-self-update.*/a\
      +zinit-message "Zinit is Nix-managed, skipping self-update"; return 0;' "$outdir/zinit-autoload.zsh"
    '';
  });
}
