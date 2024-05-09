#
# Module for enabling corporate functionality within Google.
#

# Hi! integration
[ -e /etc/bash.bashrc.d/shell_history_forwarder.sh ] && source /etc/bash.bashrc.d/shell_history_forwarder.sh

zstyle ':vcs_info:*' enable git hg svn citc

# use chg instead of hg
alias hg=chg
zstyle ':vcs_info:hg:*:-all-' command chg

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
            HG_DETAILS=$(chg log -l 1)
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

if [[ -f /etc/bash_completion.d/hgd ]]; then
  . /etc/bash_completion.d/hgd
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
