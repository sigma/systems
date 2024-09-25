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
typeset -g POWERLEVEL9K_CERT_OK_GLYPH=$'\u2714 '
typeset -g POWERLEVEL9K_CERT_EXPIRED_GLYPH=$'\u2718 '

function prompt_gcert() {
    # Use mtime on ~/.sso/cookie as an approximation of valid cert. While not
    # correct, I do not really care if I get prompted because the cert became
    # invalid in other ways: I cannot anticipate it anyway.
    # The prompt being fast is way more important, and gcertstatus is slow.
    if [[ -e ${POWERLEVEL9K_CERT_COOKIE_FILE} ]]; then
        local valid=$(($POWERLEVEL9K_CERT_VALIDITY_TIME - $EPOCHSECONDS + $(zstat +mtime ${POWERLEVEL9K_CERT_COOKIE_FILE})))
        if (( valid < 0 )); then
            p10k segment -b red -f 255 -t ${POWERLEVEL9K_CERT_EXPIRED_GLYPH}
        elif (( valid < POWERLEVEL9K_CERT_ADVANCE_WARNING )); then
            p10k segment -b yellow -f 255 -t ${POWERLEVEL9K_CERT_OK_GLYPH}
        else
            p10k segment -b green -f 255 -t ${POWERLEVEL9K_CERT_OK_GLYPH}
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
    prompt_gdir
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
