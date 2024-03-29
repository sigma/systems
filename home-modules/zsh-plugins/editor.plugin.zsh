if (( $+commands[emacsclient] )); then
    export EDITOR='emacsclient -t'
elif (( $+commands[zile] )); then
    export EDITOR='zile'
else
    export EDITOR='nano'
fi
export VISUAL=${VISUAL:-$EDITOR}
export PAGER=${PAGER:-less}
