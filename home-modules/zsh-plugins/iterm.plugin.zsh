if [ "${TERM_PROGRAM}" = "iTerm.app" -a -e "${HOME}/.iterm2_shell_integration.zsh" ]; then
    source "${HOME}/.iterm2_shell_integration.zsh"
else
    true
fi
