#!/usr/bin/env bash
# Rex counterpart of tuicr-wrapper-herdr.sh (next to this file). Upstream's
# Rex wrapper (tuicr main, not yet in the pinned release) splits the agent's
# block and returns at once; this one opens tuicr in a floating pane over the
# agent's tab instead, so the review doesn't squeeze the agent, and blocks
# until tuicr exits like the herdr popup does.
#
# Same CLI contract as the other blocking wrappers: `[directory] [-- tuicr-args...]`,
# prints the exported review between the TUICR INSTRUCTIONS markers. Sources
# _tuicr-common.sh from the skill directory it is installed into.
#
# Unlike a herdr popup a Rex floating pane is a real block: it takes the tuicr
# argv directly (no shell, no quoting round-trip) and `rex wait` returns its
# exit status, so there is no status file to poll.
set -e -u -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_tuicr-common.sh"

REX_BIN="${REX_BIN:-rex}"
JQ_BIN="${JQ_BIN:-jq}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  printf "%b[tuicr]%b %s\n" "$GREEN" "$NC" "$*"
}

log_warn() {
  printf "%b[tuicr]%b %s\n" "$YELLOW" "$NC" "$*"
}

log_error() {
  printf "%b[tuicr]%b %s\n" "$RED" "$NC" "$*" >&2
}

usage() {
  cat <<USAGE
Usage: $(basename "$0") [directory] [-- tuicr-args...]

Launch tuicr in a Rex floating pane over the agent's tab.

Arguments:
  directory    Repository directory to review (default: current directory)
  tuicr-args   Extra arguments passed through to tuicr (e.g. -w, -r <revset>)

Environment variables:
  REX_BIN      Path to the rex executable (default: rex)
  JQ_BIN       Path to the jq executable (default: jq)

Examples:
  $(basename "$0")
  $(basename "$0") ~/project
  $(basename "$0") . -- -w
USAGE
}

require_command() {
  if ! command -v "$1" &>/dev/null; then
    log_error "$2 not found on PATH"
    return 1
  fi
}

output_file=""

cleanup() {
  local status=$?
  [[ -z "$output_file" ]] || rm -f "$output_file"
  return "$status"
}

launch_tuicr_float() {
  local target_dir="$1"
  shift

  local view
  view=$("$REX_BIN" api call -s "$REX_SESSION" session.view '{}')

  # The tab holding the agent's block; the float opens over it.
  local window_id
  window_id=$(printf '%s' "$view" | "$JQ_BIN" -r --arg b "$REX_BLOCK" \
    'first(.windows[] | select(any(.layers[].blocks[]?; .block_id == $b)) | .window_id) // empty')
  if [[ -z "$window_id" ]]; then
    log_error "Could not find the tab holding $REX_BLOCK"
    return 1
  fi

  # One review per tab: a second float would hide the first, and exporting
  # nothing reads as an approval to the agent.
  local existing
  existing=$(printf '%s' "$view" | "$JQ_BIN" -r --arg w "$window_id" \
    'first(.windows[] | select(.window_id == $w) | .layers[] | select(.kind != "tiled") | .blocks[]? | select(.label == "tuicr") | .block_id) // empty')
  if [[ -n "$existing" ]]; then
    log_error "tuicr is already open in this tab ($existing); rerun once that review is closed"
    return 75
  fi

  local tuicr_bin
  tuicr_bin=$(command -v tuicr)
  local command=("$tuicr_bin" "$@")

  # Optional --stdout capture: skips tuicr's save & copy confirm dialog on
  # exit and writes the exported review straight to a file we print below.
  # The redirect needs a shell; the paths travel as positional parameters.
  local use_stdout=false
  if tuicr_stdout_supported; then
    output_file=$(mktemp /tmp/tuicr-output.XXXXXX)
    use_stdout=true
    command=(/bin/sh -c 'out=$1; shift; exec "$@" --stdout > "$out"' sh "$output_file" "${command[@]}")
    log_info "Using --stdout mode (output will be captured)"
  else
    log_warn "tuicr --stdout not supported, output will be copied to clipboard"
  fi

  local request
  request=$("$JQ_BIN" -n --arg w "$window_id" --arg cwd "$target_dir" \
    '{window_id: $w, bounds: [0.05, 0.05, 0.9, 0.9], focus: true,
      layout: {block: {flavor: "com.superlogical.terminal.shell", label: "tuicr",
        options: {cwd: $cwd, shell: "none", command: $ARGS.positional}}}}' \
    --args -- "${command[@]}") # `--`: the argv holds `-c`, a jq flag too

  log_info "Launching tuicr in a Rex floating pane"
  log_info "Directory: $target_dir"

  local block_id
  block_id=$("$REX_BIN" api call -s "$REX_SESSION" session.new_layer "$request" \
    | "$JQ_BIN" -r '.block_ids[0] // empty')
  if [[ -z "$block_id" ]]; then
    log_error "Rex did not open the floating pane"
    return 1
  fi

  log_info "tuicr is running in $block_id"
  log_info "Waiting for tuicr to exit..."

  # shortcut: a tuicr that exits before this wait starts reads as status 1;
  # a human review never ends that fast, so no handshake guards it.
  local tuicr_status=0
  "$REX_BIN" wait -s "$REX_SESSION" "$block_id" || tuicr_status=$?

  if [[ "$tuicr_status" -eq 0 ]]; then
    log_info "tuicr finished"
  else
    log_error "tuicr exited with status $tuicr_status"
  fi

  tuicr_report_stdout_output "$use_stdout" "$output_file"
  output_file=""

  return "$tuicr_status"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ -z "${REX_SESSION:-}" || -z "${REX_BLOCK:-}" ]]; then
    log_error "Not running inside a Rex block"
    echo "Run your coding agent inside Rex, then invoke the tuicr skill again."
    exit 1
  fi

  require_command "$REX_BIN" "rex"
  require_command "$JQ_BIN" "jq"
  require_command "tuicr" "tuicr"

  tuicr_parse_args "$@"
  local target_dir="$TUICR_TARGET_DIR"
  if [[ ! -d "$target_dir" ]]; then
    log_error "Directory not found: $target_dir"
    exit 1
  fi
  target_dir=$(cd "$target_dir" && pwd)

  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  launch_tuicr_float "$target_dir" "${TUICR_PASSTHROUGH_ARGS[@]+"${TUICR_PASSTHROUGH_ARGS[@]}"}"
}

main "$@"
