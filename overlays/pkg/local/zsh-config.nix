{
  stdenv,
  lib,
  coreutils,
  findutils,
  writeText,
  nix-filter,
}:
stdenv.mkDerivation {
  pname = "zsh-config";
  version = "dev";
  src = nix-filter {
    root = ./.;
    include = [
      (nix-filter.inDirectory ./zsh-config)
    ];
  };
  dontUnpack = true;

  buildPhase = let
    generated = writeText "p10k.generated.config.zsh" ''
      typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
        os_icon
        context
        dir
        vcs

        newline

        prompt_char
      )

      typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
        status
        command_execution_time
        background_jobs
        direnv
        asdf

        newline

        virtualenv
        anaconda
        pyenv
        goenv
        nodenv
        nvm
        nodeenv
        rbenv
        rvm
        fvm
        luaenv
        jenv
        plenv
        phpenv
        scalaenv
        haskell_stack
        kubecontext
        terraform
        aws
        aws_eb_env
        azure
        gcloud
        google_app_cred
        nordvpn
        ranger
        nnn
        vim_shell
        midnight_commander
        nix_shell
        todo
        timewarrior
        taskwarrior
      )

      typeset -g POWERLEVEL9K_VCS_BACKENDS=(git hg)
    '';
  in ''
    ${coreutils}/bin/cp -R $src/zsh-config/* .
    ${coreutils}/bin/cp ${generated} ./p10k.generated.config.zsh
  '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
