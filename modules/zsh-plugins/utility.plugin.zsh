#
# Utility Functions and Options
#

#
# Command Correction
#

if [[ ${zcorrection} == 'true' ]]; then
  setopt CORRECT
fi

#
# ls Colours
#

if (( ${+commands[dircolors]} )); then
  # GNU
  if [[ -s ${HOME}/.dir_colors ]]; then
    eval "$(dircolors --sh ${HOME}/.dir_colors)"
  else
    eval "$(dircolors --sh)"
  fi

  if [ "$+commands[eza]" -ne 0 ]; then
    alias ls="eza --group-directories-first"
  else
    alias ls='ls --group-directories-first --color=auto'
  fi
  
else
  # BSD

  # colors for ls and completion
  export LSCOLORS='exfxcxdxbxGxDxabagacad'
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'

  # stock OpenBSD ls does not support colors at all, but colorls does.
  if [[ $OSTYPE == openbsd* ]]; then
    if (( ${+commands[colorls]} )); then
      alias ls='colorls -G'
    fi
  else
    alias ls='ls -G'
  fi
fi

#
# grep Colours
#

export GREP_COLOR='37;45'             #BSD
export GREP_COLORS="mt=${GREP_COLOR}" #GNU
if [[ ${OSTYPE} == openbsd* ]]; then
  if (( ${+commands[ggrep]} )); then
    alias grep='ggrep --color=auto'
  fi
else
 alias grep='grep --color=auto'
fi


#
# ls Aliases
#

alias l='ls -lah'         # all files, human-readable sizes
alias lm="l | ${PAGER}"   # all files, human-readable sizes, use pager
alias ll='ls -lh'         # human-readable sizes
alias lr='ll -R'          # human-readable sizes, recursive
alias lx='ll -XB'         # human-readable sizes, sort by extension (GNU only)
alias lk='ll -Sr'         # human-readable sizes, largest last
alias lt='ll -tr'         # human-readable sizes, most recent last
alias lc='lt -c'          # human-readable sizes, most recent last, change time


#
# File Downloads
#

# order of preference: aria2c, axel, wget, curl. This order is derrived from speed based on personal tests.
if (( ${+commands[aria2c]} )); then
  alias get='aria2c --max-connection-per-server=5 --continue'
elif (( ${+commands[axel]} )); then
  alias get='axel --num-connections=5 --alternate'
elif (( ${+commands[wget]} )); then
  alias get='wget --continue --progress=bar --timestamping'
elif (( ${+commands[curl]} )); then
  alias get='curl --continue-at - --location --progress-bar --remote-name --remote-time'
fi


#
# Resource Usage
#

alias df='df -kh'
alias du='du -kh'


#
# Always wear a condom
#

if [[ ${OSTYPE} == linux* ]]; then
  alias chmod='chmod --preserve-root -v'
  alias chown='chown --preserve-root -v'
fi

# not aliasing rm -i, but if safe-rm is available, use condom.
# if safe-rmdir is available, the OS is suse which has its own terrible 'safe-rm' which is not what we want
if (( ${+commands[safe-rm]} )) && (( ! ${+commands[safe-rmdir]} )); then
  alias rm='safe-rm'
fi


#
# Misc
#

mkcd() {
  [[ -n ${1} ]] && mkdir -p ${1} && builtin cd ${1}
}
