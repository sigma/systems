# herdr comes from its own flake (see ../default.nix), whose nix/package.nix
# installs only the binary. The nixpkgs expression we used before also shipped
# shell completions, so generate them here — herdr emits them itself via
# `herdr completion <shell>`, which needs the built binary to be runnable.
final: prev: {
  herdr = prev.herdr.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.installShellFiles ];

    postInstall =
      (oldAttrs.postInstall or "")
      + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
        installShellCompletion --cmd herdr \
          --bash <("$out/bin/herdr" completion bash) \
          --fish <("$out/bin/herdr" completion fish) \
          --zsh <("$out/bin/herdr" completion zsh)
      '';
  });
}
