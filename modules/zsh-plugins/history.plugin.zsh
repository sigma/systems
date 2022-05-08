#
# Configures history options
#

# sets the location of the history file
HISTFILE="${ZDOTDIR:-${HOME}}/.zhistory"

# limit of history entries
HISTSIZE=200000
SAVEHIST=$HISTSIZE

# Perform textual history expansion, csh-style, treating the character ‘!’ specially.
setopt bang_hist

# Save each command’s beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file.
# ‘: <beginning time>:<elapsed seconds>;<command>’.
setopt extended_history

# This options works like APPEND_HISTORY except that new history lines are added to the ${HISTFILE} incrementally
# (as soon as they are entered), rather than waiting until the shell exits.
setopt inc_append_history

# Shares history across all sessions rather than waiting for a new shell invocation to read the history file.
setopt share_history

# Do not enter command lines into the history list if they are duplicates of the previous event.
setopt hist_ignore_dups

# If a new command line being added to the history list duplicates an older one, 
# the older command is removed from the list (even if it is not the previous event).
setopt hist_ignore_all_dups

# Remove command lines from the history list when the first character on the line is a space,
# or when one of the expanded aliases contains a leading space.
setopt hist_ignore_space

# When writing out the history file, older commands that duplicate newer ones are omitted.
setopt hist_save_no_dups

# Whenever the user enters a line with history expansion, don’t execute the line directly;
# instead, perform history expansion and reload the line into the editing buffer.
setopt hist_verify

# backwards search produces diff result each time
setopt hist_find_nodups

# compact consecutive white space chars (cool)
setopt hist_reduce_blanks

# don't store history related functions
setopt hist_no_store

# don't beep for erroneous history expansions
setopt no_hist_beep

# Lists the ten most used commands.
alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"

function fz-history-widget() {
    local selected=$(fc -rl 1 | fzf -n "2.." --tiebreak=index --prompt="cmd> " ${BUFFER:+-q$BUFFER})
    if [[ "$selected" != "" ]] {
           zle vi-fetch-history -n $selected
       }
}

zle -N fz-history-widget
bindkey '^R' fz-history-widget
