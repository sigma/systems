if (( $+commands[zile] )); then
    BACKUP_EDITOR='zile'
else
    BACKUP_EDITOR='nano'
fi

if (( $+commands[emacsclient] )); then
    export EDITOR="emacsclient -t -a ${BACKUP_EDITOR}"
else
    export EDITOR=${BACKUP_EDITOR}
fi

export VISUAL=${VISUAL:-$EDITOR}
