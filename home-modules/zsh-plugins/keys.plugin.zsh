autoload -U ebindkey

bindkey -e
bindkey '^[e' expand-cmd-path
bindkey '^[^I' reverse-menu-complete
bindkey '^X^N' accept-and-infer-next-history
bindkey '^[p' history-beginning-search-backward
bindkey '^[n' history-beginning-search-forward
bindkey '^[P' history-beginning-search-backward
bindkey '^[N' history-beginning-search-forward
bindkey '^I' complete-word
# bindkey '^Xi' incremental-complete-word
# bindkey '^Xa' all-matches
# bindkey '^Xm' force-menu

if zmodload zsh/deltochar >&/dev/null; then
    bindkey '^[z' zap-to-char
    bindkey '^[Z' delete-to-char
fi

# Fix weird sequence that rxvt produces
bindkey -s '^[[Z' '\t'

bindkey -s '^|l' " | less"                           # c-| l  pipe to less
bindkey -s '^|g' ' | grep ""^[OD'                    # c-| g  pipe to grep
bindkey -s '^|a' " | awk '{print $}'^[OD^[OD"        # c-| a  pipe to awk
bindkey -s '^|s' ' | sed -e "s///g"^[OD^[OD^[OD^[OD' # c-| s  pipe to sed
bindkey -s '^|w' " | wc -l"                          # c-| w  pipe to wc

insert-root-prefix () {
   local prefix
   case $(uname -s) in
      "SunOS")
         prefix="pfexec"
      ;;
      *)
         prefix="sudo"
      ;;
   esac
   BUFFER="$prefix $BUFFER"
   CURSOR=$(($CURSOR + $#prefix + 1))
}

zle -N insert-root-prefix
bindkey "^Xf" insert-root-prefix

autoload -U edit-command-line
function edit-command-line-as-zsh {
    TMPSUFFIX=.zsh
    edit-command-line
    unset TMPSUFFIX
}
zle -N edit-command-line-as-zsh
bindkey '\C-x\C-e' edit-command-line-as-zsh

function execute-command() {
    local selected=$(printf "%s\n" ${(k)widgets} | fzf --reverse --prompt="cmd> " --height=10 )
    zle redisplay
    [[ $selected ]] && zle $selected
}

zle -N execute-command
bindkey "^[x" execute-command

# make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )) {
    function zle-line-init() {
        echoti smkx
    }
    function zle-line-finish() {
        echoti rmkx
    }
    zle -N zle-line-init
    zle -N zle-line-finish
}

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

ebindkey 'Home'   beginning-of-line
ebindkey 'End'    end-of-line
ebindkey 'Delete' delete-char
ebindkey "Up"     up-line-or-beginning-search
ebindkey "Down"   down-line-or-beginning-search

ebindkey "C-Right" forward-word
ebindkey 'C-Left'  backward-word
ebindkey "C-Backspace" backward-kill-word
ebindkey 'Space' magic-space
ebindkey 'C-d'   delete-char
ebindkey 'C-w'   kill-region

ebindkey 'M-q' push-line-or-edit

ebindkey -M command "Backspace" backward-delete-char

() {
    local -a to_bind=(forward-word backward-word backward-kill-word)
    local widget
    for widget ($to_bind) {
        autoload -Uz $widget-match
        zle -N $widget-match
    }
    zstyle ':zle:*-match' word-style shell
}

ebindkey 'M-Right' forward-word-match
ebindkey 'M-Left'  backward-word-match
ebindkey "C-Backspace" backward-kill-word-match
