{
  writeShellApplication,
  quickshell,
  procps,
  coreutils,
}:
writeShellApplication {
  name = "noctalia-ipc";
  runtimeInputs = [
    quickshell
    procps
    coreutils
  ];
  text = ''
    # Retry up to 3 times with 1 second delay
    for attempt in 1 2 3; do
      pid=$(pgrep -f 'quickshell.*noctalia' | head -1)
      if [ -n "$pid" ]; then
        if quickshell ipc --pid "$pid" "$@"; then
          exit 0
        fi
      fi
      if [ "$attempt" -lt 3 ]; then
        sleep 1
      fi
    done
    echo "noctalia-ipc: failed after 3 attempts" >&2
    exit 1
  '';
}
