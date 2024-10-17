{
  pkgs,
  machine,
  ...
}: {
  enable = true;

  # dotDir = ".config/zsh";
  defaultKeymap = "emacs";

  initExtraFirst = ''
    # for nix-darwin, in case we can't install it as /etc/zshrc
    # It's idempotent anyway, so it doesn't matter if /etc/zshrc was actually installed.
    if [ -e /etc/static/zshrc ]; then
        source /etc/static/zshrc
    fi

    # for home-manager only systems
    if [[ "$PATH" != ?(*:)"$HOME/.nix-default-profile/bin"?(:*) ]]; then
        export PATH="$HOME/.nix-default-profile/bin:$PATH"
    fi
    if [[ "$PATH" != ?(*:)"$HOME/.nix-profile/bin"?(:*) ]]; then
        export PATH="$HOME/.nix-profile/bin:$PATH"
    fi

    # Set the list of directories that Zsh searches for programs.
    path=(
        $HOME/bin
        /usr/local/{bin,sbin}
        $path
    )

    if [[ -d "/usr/local/opt/coreutils/libexec/gnubin/" ]]; then
        path=(
            /usr/local/opt/coreutils/libexec/gnubin/
            $path
        )
    fi

    export GOPATH=$HOME

    # minimal configuration for dumb shells (typically Emacs TRAMP)
    if [[ "$TERM" = "dumb" ]]; then
      unset zle_bracketed_paste
      setopt nozle
      setopt nopromptcr
      setopt nopromptsubst
      if whence -w precmd >/dev/null; then
          unfunction precmd
      fi
      if whence -w preexec >/dev/null; then
          unfunction preexec
      fi
      PS1='$ '
      return
    fi

    #
    # User configuration sourced by interactive shells
    #

    #
    # Language
    #

    if [[ -z "$LANG" ]]; then
      export LANG='en_US.UTF-8'
    fi

    export CLICOLOR=1

    WORDCHARS=""

    # I abuse this variable in non-screen contexts to convey TERM_PROGRAM, which I
    # actually need
    if [[ -n "$WINDOW" ]]; then
      if ! [[ "$WINDOW" =~ '^[0-9+$]' ]]; then
        export TERM_PROGRAM="$WINDOW"
        unset WINDOW
      fi
    fi

    USE_NERD_FONTS="$USE_NERD_FONTS"
    if [[ -z "$USE_NERD_FONTS" ]]; then
      if [[ "$TERM_PROGRAM" == sshapp ]]; then
        # chromeos. I guess it'd be possible to try harder, but I can't be bothered.
        USE_NERD_FONTS=""
      elif [[ "$TERM_PROGRAM" == iTerm.app || "$TERM_PROGRAM" == vscode || -n "$SSH_AUTH_SOCK" ]]; then
        USE_NERD_FONTS=1
      fi
    fi
  '';

  zinit.enable = true;

  zinit.pre = ''
    fpath+=${pkgs.zsh-config}/functions
    for plug in ${pkgs.zsh-config}/*.plugin.zsh; do
      source $plug
    done
  '';

  zinit.plugins = [
    {
      name = "zdharma-continuum/zinit-annex-as-monitor";
      light = true;
    }
    {
      name = "zdharma-continuum/zinit-annex-patch-dl";
      light = true;
    }
    {
      name = "zdharma-continuum/zinit-annex-submods";
      light = true;
    }
    {
      name = "zdharma-continuum/zinit-annex-bin-gem-node";
      light = true;
    }
    {
      name = "zdharma-continuum/zinit-annex-rust";
      light = true;
    }
    {
      name = "Aloxaf/fzf-tab";
      tags = ["wait=1" "lucid"];
      pre = "
zstyle ':fzf-tab:*' single-group ''
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:cd:*' query-string prefix longest
zstyle ':fzf-tab:*' switch-group '<' '>'
";
    }
    {
      name = "zdharma-continuum/fast-syntax-highlighting";
      tags = ["wait=1" "lucid" "atinit=\"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay\""];
    }
    {
      name = "zsh-users/zsh-autosuggestions";
      tags = ["wait=1" "lucid" "atload=\"!_zsh_autosuggest_start\""];
      pre = ''
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
        ZSH_AUTOSUGGEST_USE_ASYNC=1
        ZSH_AUTOSUGGEST_MANUAL_REBIND=1
      '';
    }
    {
      name = "zsh-users/zsh-completions";
      tags = ["wait=1" "lucid" "blockf" "atinit=\"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay\""];
    }
    {
      name = "spwhitt/nix-zsh-completions";
      tags = ["wait=1" "lucid" "blockf" "atinit=\"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay\""];
    }
    {
      name = "hlissner/zsh-autopair";
      tags = ["wait=1" "lucid"];
    }
    {
      name = "urbainvaes/fzf-marks";
      tags = ["wait=1" "lucid"];
    }
    {
      name = "hchbaw/zce.zsh";
      tags = ["wait=1" "lucid" "atload=\"bindkey '^Xz' zce\""];
    }
    {
      name = "chisui/zsh-nix-shell";
      tags = ["wait=2" "lucid"];
    }
    {
      name = "zdharma-continuum/declare-zsh";
      tags = ["wait=2" "lucid"];
    }
    {
      name = "zdharma-continuum/zui";
      tags = ["wait=2" "lucid" "blockf"];
    }
    {
      name = "zdharma-continuum/zinit-console";
      tags = ["wait=2" "lucid"];
    }
    {
      name = "zdharma-continuum/zinit-crasis";
      tags = ["wait=2" "lucid" "trigger-load='!crasis'"];
    }
    {
      name = "wfxr/forgit";
      tags = ["wait=2" "lucid"];
    }
    {
      name = "chriskempson/base16-shell";
      light = true;
      tags = ["lucid" "atload=base16_monokai"];
    }
    {
      name = "romkatv/powerlevel10k";
      light = true;
      tags = ["depth:1" "lucid" "atload:'source ${pkgs.zsh-config}/p10k.config.zsh; _p9k_precmd'" "nocd"];
    }
  ];

  initExtra = ''
    zinit pack for dircolors-material

    # local settings
    [[ -s $HOME/.localrc ]] && source $HOME/.localrc

    function rehash () {
        hash -r
        hash -rd
        [ -e $HOME/.local.hashes ] && source ~/.local.hashes || true
    }

    rehash
  '';
}
