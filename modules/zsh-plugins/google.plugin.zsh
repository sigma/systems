#
# Module for enabling corporate functionality within Google.
#

# Hi! integration
[ -e /etc/bash.bashrc.d/shell_history_forwarder.sh ] && source /etc/bash.bashrc.d/shell_history_forwarder.sh

POWERLEVEL9K_CUSTOM_HI="prompt_zsh_hi"

prompt_zsh_hi() {
  if [[ "${__hi_active}" == true ]]; then
    echo -n "Hi!"
  fi
}

zstyle ':vcs_info:*' enable git hg svn citc

# use chg instead of hg
alias hg=chg
zstyle ':vcs_info:hg:*:-all-' command /usr/bin/chg

# Citc integration
VCS_INFO_detect_citc() {
  [[ $1 == '--flavours' ]] && { print -l citc; return 0 }

  if [[ ${PWD} =~ '(/google/src/cloud/[^/]+/(.+))/google3(.*)' ]]; then
    return 0
  fi
  return 1
}

VCS_INFO_get_data_citc() {
    if [[ ${PWD} =~ '(/google/src/cloud/[^/]+/(.+))/google3(.*)' ]]; then
        if [[ -d "${match[1]}/.hg" ]]; then
            HG_DETAILS=$(/usr/bin/chg log -l 1)
            HG_CL_NUMBER=$(echo $HG_DETAILS | grep -m2 "pending CL:" | tail -n1 | awk '{print $3}')
            CUSTOM_GLYPH=$'\uf407'
            VCS_INFO_formats "" "$CUSTOM_GLYPH $HG_CL_NUMBER" "" "" "" "" ""
        else
            last_cl=$(citctools background ${match[1]}/.citc/annotations/devtools_srcfs.ViewConfig)
            VCS_INFO_formats "" "citc@${last_cl}" "" "" "" "" ""
        fi
        return 0
    fi
    return 1
}

# Piper completion
if [[ -f /etc/bash_completion.d/g4d ]]; then
  . /etc/bash_completion.d/p4
  . /etc/bash_completion.d/g4d
fi

# Alias --help ; ignore rest of the line
alias -g -- -help="-help | less -FX ; true "
alias -g -- --help="--help | less -FX ; true "
alias -g -- --helpfull="--helpfull | less -FX ; true "

alias cider='/google/src/head/depot/google3/experimental/cider_here/cider_here.sh'

# Alias for paste
# https://cs.corp.google.com/piper///depot/eng/tools/pastebin
alias pastebin="/google/src/head/depot/eng/tools/pastebin"

# Nicer `g4 p` output that makes copying and pasting file names easier
export G4PENDINGSTYLE=relativepath

# Function for running iblaze in tmux panel and change it's caption, depending of the result.
ibl() {
  iblaze test --test_output=all $1 \
         -iblaze_run_before="clear && tmux rename-window -t`tmux display-message -p '#I'` '*running*'" \
         -iblaze_run_after="tmux rename-window -t`tmux display-message -p '#I'` 'success :)'" \
         -iblaze_run_after_failure="tmux rename-window -t`tmux display-message -p '#I'` 'failure :('"
}


# # Function for showing loas status in prompt.
# # Calling asynchronously.
# loas_status() {
#     if (( $+commands[prodaccess] )); then
#         # glinux
#         prodcertstatus --nobinarylog --disable_log_to_disk --check_remaining_hours=1 > /dev/null 2>&1
#     else
#         # probably gmac
#         gcertstatus --check_remaining=1h --ssh_cert_comment="corp/normal" --quiet > /dev/null 2>&1
#     fi
#     result=$?
#     if [ $result -eq 0 ]; then
#         print -r ""
#     elif [ $result -eq 2 ]; then
#         # one hour left for prodcertstatus
#         print -r "%B%F{magenta}1hr %f%b"
#     elif [ $result -eq 91 ]; then
#         # one hour left for gcertstatus
#         print -r "%B%F{magenta}1hr %f%b"
#     else
#         # expired
#         print -r "%B%F{red}!!! %f%b"
#     fi
# }

# # Initialize zsh-async
# async_init

# # Start workers that will report job completion
# async_start_worker loas_prompt_worker -n

# completed_loas_status_callback() {
#     local output=$3
#     H_PROMPT_LOAS=$output
#     async_job loas_prompt_worker loas_status
# }

# # Register our callback function to run when the job completes
# async_register_callback loas_prompt_worker completed_loas_status_callback

# # Start the job
# async_job loas_prompt_worker loas_status

# if [[ $RPROMPT != *'${H_PROMPT_LOAS}'* ]]; then
#     RPROMPT='${H_PROMPT_LOAS}'$RPROMPT
# fi

# TMOUT=5
# TRAPALRM() {
#     if ! [[ "$WIDGET" =~ ^(complete-word|fzf-completion)$  ]]; then
#         zle && { zle reset-prompt; zle -R  }
#     fi
# }
