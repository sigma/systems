export ROOT=${0:a:h}

if [[ -n "$USE_NERD_FONTS" ]]; then
  [[ ! -f ${ROOT}/p10k.zsh ]] || source ${ROOT}/p10k.zsh
else
  [[ ! -f ${ROOT}/p10k.pure.zsh ]] || source ${ROOT}/p10k.pure.zsh
fi

[[ ! -f ${ROOT}/p10k.generated.config.zsh ]] || source ${ROOT}/p10k.generated.config.zsh

typeset -g POWERLEVEL9K_DIR_FOREGROUND=black
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=black
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=black

typeset -g POWERLEVEL9K_STATUS_OK=false

typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=30%

[[ ! -f ${ROOT}/p10k.google.zsh ]] || source ${ROOT}/p10k.google.zsh
