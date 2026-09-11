#!/usr/bin/env bash
# Runs *inside* the herdr popup. Launched by herdr from the plugin manifest,
# which is an argv array with no shell, so everything dynamic arrives through
# the environment set by the agent-side wrapper (tuicr-wrapper-herdr.sh):
#
#   TUICR_BIN    tuicr binary the wrapper resolved (falls back to PATH)
#   TUICR_ARGS   pass-through tuicr args, bash-%q quoted, space separated
#   TUICR_OUT    if set, capture `tuicr --stdout` here
#   TUICR_DONE   file that receives tuicr's exit status; the wrapper polls it
#
# The popup is not a herdr pane: it has no pane ID and `pane wait-output`
# cannot watch it, so the exit-status file is the only completion signal the
# wrapper gets. Write it from an EXIT trap so a tuicr crash still unblocks the
# wrapper instead of leaving it polling forever.
set -u

status=1
trap 'echo "$status" > "$TUICR_DONE"' EXIT

eval "set -- ${TUICR_ARGS:-}"

tuicr_bin="${TUICR_BIN:-tuicr}"
if [[ -n "${TUICR_OUT:-}" ]]; then
  "$tuicr_bin" "$@" --stdout > "$TUICR_OUT"
else
  "$tuicr_bin" "$@"
fi
status=$?
