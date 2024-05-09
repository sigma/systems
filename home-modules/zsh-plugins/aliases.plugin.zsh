#!/bin/zsh

if [ "$+commands[bat]" -ne 0 ]; then
    alias cat="bat -pp"
fi

alias grep='command grep --color'

# alias -g ...=../..
# alias -g ....=../../..
# alias -g .....=../../../..
# alias -g ......=../../../../..
alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'
alias cd.....='cd ../../../..'

alias cd/='cd /'

alias 1='cd -'
alias 2='cd +2'
alias 3='cd +3'
alias 4='cd +4'
alias 5='cd +5'
alias 6='cd +6'
alias 7='cd +7'
alias 8='cd +8'
alias 9='cd +9'

alias md='mkdir -p'
alias rd=rmdir

alias d='dirs -v'

alias mmv='noglob zmv -W'

alias j='jobs -l'
alias dn=disown

alias h='history -$LINES'

alias ts=typeset

alias cls='clear'
alias term='echo $TERM'

if (( $+commands[pinfo] )); then
    alias info='pinfo'
fi

alias f=fuck

alias mv='nocorrect mv'
#alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'
alias man='nocorrect man'
alias find='noglob find'
alias gcc='nocorrect gcc'
alias mkdir='nocorrect mkdir'

# enable ^Z for nano
alias nano='/usr/bin/nano -z'

# change some applications
if (( $+commands[zile] )); then
    alias vi='zile'
fi

if (( $+commands[htop] )); then
    alias top='htop'
fi

if (( $+commands[lftp] )); then
    alias ftp='lftp'
elif (( $+commands[ncftp] )); then
    alias ftp='ncftp'
fi

alias tf='less +F'
alias tfs='less -S +F'

alias bz=bzip2
alias buz=bunzip2

alias -s pdf=open
alias -s html=open
alias -s tgz='tar zxvf'

alias assh="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
alias ascp="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

alias vsc-restart='systemctl --user restart code-server'
