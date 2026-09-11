#!/usr/bin/env bash
# Drop-in replacement for tuicr's own skills/tuicr/tuicr-wrapper-herdr.sh.
# Upstream splits the agent's pane and drives tuicr through `pane run` /
# `pane wait-output`; this one opens tuicr in a herdr *popup* instead, via the
# `tuicr` herdr plugin (herdr-plugin.toml next to this file), so the review
# floats over the layout rather than squeezing the agent's pane.
#
# Same CLI contract as upstream: `[directory] [-- tuicr-args...]`, blocks until
# tuicr exits, prints the exported review between the TUICR INSTRUCTIONS
# markers. Sources _tuicr-common.sh from the skill directory it is installed
# into, exactly like the upstream wrappers.
set -e -u -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_tuicr-common.sh"

HERDR_BIN="${HERDR_BIN:-${HERDR_BIN_PATH:-herdr}}"
JQ_BIN="${JQ_BIN:-jq}"
TUICR_HERDR_PLUGIN="${TUICR_HERDR_PLUGIN:-tuicr}"
TUICR_HERDR_ENTRYPOINT="${TUICR_HERDR_ENTRYPOINT:-review}"

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

Launch tuicr in a Herdr popup.

Arguments:
  directory    Repository directory to review (default: current directory)
  tuicr-args   Extra arguments passed through to tuicr (e.g. -w, -r <revset>)

Environment variables:
  HERDR_BIN             Path to the Herdr executable (default: \$HERDR_BIN_PATH, then herdr)
  JQ_BIN                Path to the jq executable (default: jq)
  TUICR_HERDR_PLUGIN    Herdr plugin id providing the popup (default: tuicr)
  TUICR_HERDR_ENTRYPOINT  Plugin pane entrypoint to open (default: review)

Examples:
  $(basename "$0")
  $(basename "$0") ~/project
  $(basename "$0") . -- -w
USAGE
}

require_command() {
  local command_name="$1"
  local display_name="$2"

  if ! command -v "$command_name" &>/dev/null; then
    log_error "$display_name not found on PATH"
    return 1
  fi
}

done_file=""
output_file=""

cleanup() {
  local status=$?
  rm -f "$done_file"
  return "$status"
}

launch_tuicr_popup() {
  local target_dir="$1"
  shift
  local tuicr_args=("$@")

  log_info "Launching tuicr in a Herdr popup"
  log_info "Directory: $target_dir"

  local tuicr_bin
  tuicr_bin=$(command -v tuicr)

  # Optional --stdout capture: skips tuicr's save & copy confirm dialog on
  # exit and writes the exported review straight to a file we print below.
  local use_stdout=false
  if tuicr_stdout_supported; then
    output_file=$(mktemp /tmp/tuicr-output.XXXXXX)
    use_stdout=true
    log_info "Using --stdout mode (output will be captured)"
  else
    log_warn "tuicr --stdout not supported, output will be copied to clipboard"
  fi

  # The popup has no pane ID, so there is nothing to `pane wait-output` on.
  # The popup-side script (tuicr-popup.sh) writes tuicr's exit status to this
  # file when it finishes, and we poll for it.
  done_file=$(mktemp /tmp/tuicr-done.XXXXXX)
  rm -f "$done_file"

  # Manifest commands are argv arrays run without a shell, so the dynamic
  # parts travel as environment variables. The args are bash-%q quoted and
  # `eval`ed back into an array on the other side.
  local quoted_args
  quoted_args=$(tuicr_quote_args "${tuicr_args[@]+"${tuicr_args[@]}"}")

  local open_response
  if ! open_response=$("$HERDR_BIN" plugin pane open \
      --plugin "$TUICR_HERDR_PLUGIN" \
      --entrypoint "$TUICR_HERDR_ENTRYPOINT" \
      --cwd "$target_dir" \
      --env "TUICR_BIN=$tuicr_bin" \
      --env "TUICR_ARGS=${quoted_args# }" \
      --env "TUICR_OUT=$output_file" \
      --env "TUICR_DONE=$done_file" 2>&1); then
    log_error "Herdr refused to open the popup:"
    printf '%s\n' "$open_response" >&2
    return 1
  fi

  local result_type
  result_type=$(printf '%s\n' "$open_response" | "$JQ_BIN" -r '.result.type // .error.code // "unknown"')
  if [[ "$result_type" != "ok" ]]; then
    # e.g. `ui_busy`: Settings, copy mode or another popup is already up.
    log_error "Herdr did not open the popup ($result_type):"
    printf '%s\n' "$open_response" >&2
    return 1
  fi

  log_info "tuicr is running in a Herdr popup"
  log_info "Waiting for tuicr to exit..."

  until [[ -s "$done_file" ]]; do
    sleep 0.5
  done

  local tuicr_status
  tuicr_status=$(<"$done_file")
  if [[ ! "$tuicr_status" =~ ^[0-9]+$ ]]; then
    log_error "Could not read tuicr exit status from popup"
    return 1
  fi

  if [[ "$tuicr_status" -eq 0 ]]; then
    log_info "tuicr finished"
  else
    log_error "tuicr exited with status $tuicr_status"
  fi

  tuicr_report_stdout_output "$use_stdout" "$output_file"

  return "$tuicr_status"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "${HERDR_ENV:-}" != "1" ]]; then
    log_error "Not running inside a Herdr-managed pane"
    echo "Run your coding agent inside Herdr, then invoke the tuicr skill again."
    exit 1
  fi

  require_command "$HERDR_BIN" "Herdr"
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

  launch_tuicr_popup "$target_dir" "${TUICR_PASSTHROUGH_ARGS[@]+"${TUICR_PASSTHROUGH_ARGS[@]}"}"
}

main "$@"
