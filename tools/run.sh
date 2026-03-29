#!/usr/bin/env zsh
# Launch the iTerm2 dev build with interactive reload support.
# Usage: run.sh <app-executable> <build-dir> [app-args...]
#
# Keys:
#   r / R  — rebuild (make Development) and relaunch
#   q / Q  — quit
#   Ctrl-C — quit

set -uo pipefail

APP_EXEC="$1"
BUILD_DIR="$2"
shift 2
APP_ARGS=("$@")

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"

app_pid=""
saved_stty=$(stty -g)

stop_app() {
  [[ -z "$app_pid" ]] && return
  kill -TERM "$app_pid" 2>/dev/null || true
  wait "$app_pid" 2>/dev/null || true
  app_pid=""
}

launch_app() {
  "$APP_EXEC" "${APP_ARGS[@]}" &
  app_pid=$!
  print "▶  iTerm2 launched (PID $app_pid) — r to rebuild+reload · q to quit"
}

cleanup() {
  trap - EXIT INT TERM
  stop_app
  stty "$saved_stty"
  print ""
  exit 0
}

rebuild_and_reload() {
  stop_app
  print "⟳  Building…"
  if make -C "$PROJECT_DIR" Development BUILD_DIR="$BUILD_DIR"; then
    print "✓  Build succeeded"
    launch_app
  else
    print "✗  Build failed — fix errors and press r to retry"
  fi
}

trap cleanup INT TERM EXIT

stty -echo -icanon min 1 time 0

launch_app

while true; do
  read -rk1 key
  case "$key" in
    r|R) rebuild_and_reload ;;
    q|Q) cleanup ;;
  esac
done
