{config, ...}: {
  enable = true;

  # dotDir = ".config/zsh";
  defaultKeymap = "emacs";

  initExtraFirst = ''
    # for nix-darwin, in case we can't install it as /etc/zshrc
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

    export DOTREPO=$HOME/.dotdrop

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

    # I like my case-semi-sensitive completion better
    zstyle ':completion:*:complete:*' matcher-list 'm:{a-z}={A-Z}'

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
        USE_NERD_FONTS=""
      elif [[ "$TERM_PROGRAM" == iTerm.app || "$TERM_PROGRAM" == vscode || -n "$SSH_AUTH_SOCK" ]]; then
        USE_NERD_FONTS=1
      fi
    fi
  '';

  enableCompletion = false;

  zinit.enable = true;

  zinit.pre = ''
    for plug in ~/.zsh-plugins/*; do
      zinit load $plug
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
      name = "Aloxaf/fzf-tab";
      tags = ["wait=1" "lucid"];
      pre = "
local extract=\"
# trim input
local in=\\\${\\\${\\\"\\\$(<{f})\\\"%\\\$'\\0'*}#*\\\$'\\0'}
# get ctxt for current completion
local -A ctxt=(\\\"\\\${(@ps:\\2:)CTXT}\\\")
# real path
local realpath=\\\${ctxt[IPREFIX]}\\\${ctxt[hpre]}\\\$in
realpath=\\\${(Qe)~realpath}
\"

zstyle ':fzf-tab:*' single-group ''
zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
zstyle ':fzf-tab:complete:cd:*' extra-opts --preview=$extract'exa -1 --color=always $realpath'
";
    }
    {
      name = "junegunn/fzf";
      tags = ["wait=1" "lucid" "depth=1" "bindmap='^T -> ^F; ^R -> ^X^R; \ec -> ^[g'" "pick=shell/key-bindings.zsh"];
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
      tags = ["lucid" "atload=base16_solarized-dark"];
    }
    {
      name = "romkatv/powerlevel10k";
      light = true;
      tags = ["depth:1" "lucid" "atload:'source ~/.p10k.config.zsh; _p9k_precmd'" "nocd"];
    }
  ];

  initExtra = ''
    zinit pack for dircolors-material

    export FZF_COMPLETION_TRIGGER='~~'
    export FZF_COMPLETION_OPTS='+c -x'
    export FZF_DEFAULT_OPTS="--multi --inline-info --bind='ctrl-o:execute(code {})+abort'"
    export FZF_CTRL_R_OPTS='--sort'

    if [ "$+commands[fd]" -ne 0 ]; then
        export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --ansi"
        export FZF_DEFAULT_COMMAND="fd --type f --color=always"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --hidden"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude ".git" .'
        _fzf_compgen_path() {
            fd --hidden --follow --exclude ".git" . "$1"
        }

        _fzf_compgen_dir() {
            fd --type d --hidden --follow --exclude ".git" . "$1"
        }
    fi

    if [ "$+commands[bat]" -ne 0 ]; then
        export FZF_CTRL_T_OPTS="--preview-window 'right:60%' --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
    fi

    [[ -s $HOME/.localrc ]] && source $HOME/.localrc

    function rehash () {
        hash -r
        hash -rd
        [ -e $HOME/.local.hashes ] && source ~/.local.hashes || true
    }

    rehash
  '';
}
