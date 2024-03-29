if [[ -n "$USE_NERD_FONTS" ]]; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
else
  [[ ! -f ~/.p10k.pure.zsh ]] || source ~/.p10k.pure.zsh
fi

[[ ! -f ~/.p10k.generated.config.zsh ]] || source ~/.p10k.generated.config.zsh

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  hi
  os_icon
  context
  citc
  gdir
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

  gcert
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

typeset -g POWERLEVEL9K_STATUS_OK=false

typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=30%

typeset -g POWERLEVEL9K_VCS_BACKENDS=(git hg citc)

function prompt_hi() {
  local active
  if [[ "${__hi_active}" == true ]]; then
    active=1
  fi
  p10k segment -b red -f white -t 'Hi!' -c "$active"
}

function instant_prompt_hi() {
  prompt_hi
}

# default duration is 20 hours -> 72000 seconds
typeset -g POWERLEVEL9K_CERT_VALIDITY_TIME=72000
# 1 hour warning
typeset -g POWERLEVEL9K_CERT_ADVANCE_WARNING=3600
# gcert glyph
typeset -g POWERLEVEL9K_CERT_GLYPH=$'\uf623 '

function prompt_gcert() {
    # Use mtime on ~/.sso/cookie as an approximation of valid cert. While not
    # correct, I do not really care if I get prompted because the cert became
    # invalid in other ways: I cannot anticipate it anyway.
    # The prompt being fast is way more important, and gcertstatus is slow.
    if [[ -e ${POWERLEVEL9K_CERT_COOKIE_FILE} ]]; then
        local valid=$(($POWERLEVEL9K_CERT_VALIDITY_TIME - $EPOCHSECONDS + $(zstat +mtime ${POWERLEVEL9K_CERT_COOKIE_FILE})))
        if (( valid < 0 )); then
            p10k segment -b red -f 255 -t ${POWERLEVEL9K_CERT_GLYPH}
        elif (( valid < POWERLEVEL9K_CERT_ADVANCE_WARNING )); then
            p10k segment -b yellow -f 255 -t ${POWERLEVEL9K_CERT_GLYPH}
        else
            p10k segment -b green -f 255 -t ${POWERLEVEL9K_CERT_GLYPH}
        fi
    fi
}

function instant_prompt_gcert() {
    prompt_gcert
}

function prompt_gdir() {
    dir=$(pwd)
    if [[ "$dir" =~ ^(\/google\/src\/cloud)(\/([^/]+\/)*)google3/?(.*)$ ]]; then
        CURRENT_DIRECTORY="//${match[4]}"
        CUSTOM_GLYPH=$'\uf1a0 '
        p10k segment -b blue -f ${POWERLEVEL9K_DIR_ANCHOR_FOREGROUND} -t "$CUSTOM_GLYPH $CURRENT_DIRECTORY"
    else
        prompt_dir
    fi
}

function instant_prompt_gdir() {
    prompt_dir
}

function prompt_citc() {
    dir=$(pwd)

    if [[ "$dir" =~ ^(\/google\/src\/cloud\/([^\/]*)\/)([^\/]*)(\/*([^/]+\/)*)(.*)* ]]; then
        CITC_CLIENT_NAME="${match[3]}"
        CUSTOM_GLYPH=$'\uf0c2 '
    else
        CITC_CLIENT_NAME=''
    fi

    p10k segment -b yellow -f '#000000' -c "$CITC_CLIENT_NAME" -t "$CUSTOM_GLYPH $CITC_CLIENT_NAME"
}

function instant_prompt_citc() {
    prompt_citc
}
