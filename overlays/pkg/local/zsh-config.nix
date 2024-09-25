{
  stdenv,
  lib,
  coreutils,
  findutils,
  writeText,
  nix-filter,
  google ? false,
}:
stdenv.mkDerivation {
  pname = "zsh-config";
  version = "dev";
  src = nix-filter {
    root = ./.;
    include = [
      (nix-filter.inDirectory ./zsh-config)
    ];
    exclude = lib.optionals (!google) [
      ./zsh-config/google.plugin.zsh
      ./zsh-config/p10k.google.zsh
    ];
  };
  dontUnpack = true;

  buildPhase = let
    gcertCookie =
      if stdenv.system == "x86_64-linux"
      then "/var/run/ccache/sso-$USER/cookie"
      else "$HOME/.sso/cookie";
    hiElement =
      if google
      then "hi"
      else "";
    citcElement =
      if google
      then "citc"
      else "";
    dirElement =
      if google
      then "gdir"
      else "dir";
    gcertElement =
      if google
      then "gcert"
      else "";
    generated = writeText "p10k.generated.config.zsh" ''
      ${
        if google
        then ''
          typeset -g POWERLEVEL9K_CERT_COOKIE_FILE="${gcertCookie}"
        ''
        else ""
      }

      typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
        ${hiElement}
        os_icon
        context
        ${citcElement}
        ${dirElement}
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

        ${gcertElement}
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

      typeset -g POWERLEVEL9K_VCS_BACKENDS=(git hg ${citcElement})
    '';
  in
    ''
      ${coreutils}/bin/cp -R $src/zsh-config/* .
    ''
    + lib.optionalString google ''
      ${coreutils}/bin/cp ${generated} ./p10k.generated.config.zsh
    '';

  installPhase = ''
    ${findutils}/bin/find . -exec ${coreutils}/bin/install -vDm 755 {} $out/{} \;
  '';
}
