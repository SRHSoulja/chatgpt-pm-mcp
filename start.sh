#!/bin/bash
# start.sh — start the ChatGPT PM MCP server and ngrok together
# Run this once. Then open your project in Claude Code and type /chatgpt-session.
# Both are required. Neither is optional.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SERVER="$SCRIPT_DIR/.server.log"
LOG_NGROK="$SCRIPT_DIR/.ngrok.log"
PIDFILE_SERVER="$SCRIPT_DIR/.server.pid"
PIDFILE_NGROK="$SCRIPT_DIR/.ngrok.pid"

start_server() {
  if [[ -f "$PIDFILE_SERVER" ]] && kill -0 "$(cat "$PIDFILE_SERVER")" 2>/dev/null; then
    echo "MCP server already running (pid $(cat "$PIDFILE_SERVER"))"
  else
    cd "$SCRIPT_DIR"
    nohup node server.js >> "$LOG_SERVER" 2>&1 &
    echo $! > "$PIDFILE_SERVER"
    echo "MCP server started (pid $!)"
  fi
}

start_ngrok() {
  if [[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null; then
    echo "ngrok already running (pid $(cat "$PIDFILE_NGROK"))"
  else
    nohup ngrok http 3333 >> "$LOG_NGROK" 2>&1 &
    echo $! > "$PIDFILE_NGROK"
    echo "ngrok started (pid $!) — check .ngrok.log for your URL"
  fi
}

stop() {
  for pidfile in "$PIDFILE_SERVER" "$PIDFILE_NGROK"; do
    if [[ -f "$pidfile" ]]; then
      kill "$(cat "$pidfile")" 2>/dev/null && echo "Stopped $(cat "$pidfile")"
      rm -f "$pidfile"
    fi
  done
}

status() {
  echo "Server: $([[ -f "$PIDFILE_SERVER" ]] && kill -0 "$(cat "$PIDFILE_SERVER")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_SERVER"))" || echo "STOPPED")"
  echo "ngrok:  $([[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_NGROK"))" || echo "STOPPED")"
  echo ""
  echo "NEXT STEP: open Claude Code in your project and type /chatgpt-session"
  echo "(the watcher MUST be running — it and this server are not optional separately)"
}

case "${1:-start}" in
  start)
    start_server
    sleep 1
    start_ngrok
    sleep 2
    echo ""
    echo "Server + ngrok are running."
    echo ""
    echo "REQUIRED NEXT STEP:"
    echo "  cd /your/project && claude"
    echo "  Then type: /chatgpt-session"
    echo ""
    echo "The watcher is the other half of this setup."
    echo "Do not skip it — ChatGPT prompts will queue but nothing will execute."
    ;;
  stop)   stop ;;
  status) status ;;
  restart) stop; sleep 1; bash "$0" start ;;
  *) echo "Usage: bash start.sh [start|stop|status|restart]" ;;
esac
