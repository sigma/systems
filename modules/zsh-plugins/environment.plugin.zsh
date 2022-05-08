#
# generic options and environment settings
#

# use smart URL pasting and escaping
autoload -Uz is-at-least
if [[ ${ZSH_VERSION} != 5.1.1 ]]; then
  if is-at-least 5.2; then
    autoload -Uz bracketed-paste-url-magic
    zle -N bracketed-paste bracketed-paste-url-magic
  else
    if is-at-least 5.1; then
      autoload -Uz bracketed-paste-magic
      zle -N bracketed-paste bracketed-paste-magic
    fi
    autoload -Uz url-quote-magic
    zle -N self-insert url-quote-magic
  fi
fi

# Treat single word simple commands without redirection as candidates for resumption of an existing job.
setopt auto_resume

# List jobs in the long format by default. 
setopt long_list_jobs

# Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt notify

# Run all background jobs at a lower priority. This option is set by default.
setopt bg_nice

# Send the HUP signal to running jobs when the shell exits.
setopt no_hup

# Report the status of background and suspended jobs before exiting a shell with job control; 
# a second attempt to exit the shell will succeed. 
# NO_CHECK_JOBS is best used only in combination with NO_HUP, else such jobs will be killed automatically
setopt no_check_jobs

# accept comments in interactive mode
setopt interactive_comments
