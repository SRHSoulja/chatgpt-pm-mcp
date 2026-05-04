#!/bin/bash
# start.sh — start the ChatGPT PM MCP server and ngrok together
# Run this once. Then open your project in Claude Code and type /chatgpt-session.
# Both the server and the watcher are required. Neither is optional.
#
# Supported: Linux, macOS, Windows via WSL2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SERVER="$SCRIPT_DIR/.server.log"
LOG_NGROK="$SCRIPT_DIR/.ngrok.log"
PIDFILE_SERVER="$SCRIPT_DIR/.server.pid"
PIDFILE_NGROK="$SCRIPT_DIR/.ngrok.pid"
NGROK_URL_TIMEOUT=15  # seconds to wait for tunnel URL

# ── ngrok preflight ────────────────────────────────────────────────────────────
check_ngrok() {
  if ! command -v ngrok &>/dev/null; then
    echo ""
    echo "ERROR: ngrok is not installed."
    echo ""
    echo "ngrok is required so ChatGPT (a cloud service) can reach your local MCP server."
    echo ""
    echo "Install ngrok:"
    echo "  Linux/WSL2:"
    echo "    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null"
    echo "    echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list"
    echo "    sudo apt update && sudo apt install ngrok"
    echo ""
    echo "  macOS (with Homebrew):"
    echo "    brew install ngrok"
    echo ""
    echo "  Or download from: https://ngrok.com/download"
    echo ""
    echo "After installing, get a free auth token:"
    echo "  1. Go to https://ngrok.com and sign up for a free account"
    echo "  2. After signing in, go to: https://dashboard.ngrok.com/authtokens"
    echo "  3. Copy your token, then run:"
    echo "     ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo ""
    echo "Windows users: run this inside your WSL2 terminal, not PowerShell."
    echo ""
    return 1
  fi

  # Check if ngrok has an authtoken configured
  local ngrok_config
  ngrok_config="${HOME}/.config/ngrok/ngrok.yml"
  if [[ ! -f "$ngrok_config" ]] || ! grep -q "authtoken" "$ngrok_config" 2>/dev/null; then
    # Also check legacy path
    local legacy_config="${HOME}/.ngrok2/ngrok.yml"
    if [[ ! -f "$legacy_config" ]] || ! grep -q "authtoken" "$legacy_config" 2>/dev/null; then
      echo ""
      echo "WARNING: ngrok may not be authenticated."
      echo ""
      echo "If the tunnel fails to start:"
      echo "  1. Sign up free at https://ngrok.com"
      echo "  2. Get your token at: https://dashboard.ngrok.com/authtokens"
      echo "  3. Run: ngrok config add-authtoken YOUR_TOKEN_HERE"
      echo ""
    fi
  fi

  return 0
}

# ── server ─────────────────────────────────────────────────────────────────────
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

# ── ngrok ──────────────────────────────────────────────────────────────────────
start_ngrok() {
  # Reuse if already running
  if [[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null; then
    echo "ngrok already running (pid $(cat "$PIDFILE_NGROK"))"
    echo "Getting existing tunnel URL..."
    get_ngrok_url
    return
  fi

  # Clear old log so URL grep is unambiguous
  > "$LOG_NGROK"
  nohup ngrok http 3333 --log=stdout >> "$LOG_NGROK" 2>&1 &
  echo $! > "$PIDFILE_NGROK"
  echo "ngrok starting (pid $!)..."
  get_ngrok_url
}

# Wait for ngrok to print a tunnel URL, then display it
get_ngrok_url() {
  local elapsed=0
  local url=""
  while [[ $elapsed -lt $NGROK_URL_TIMEOUT ]]; do
    url=$(grep -oP 'url=https://\S+' "$LOG_NGROK" 2>/dev/null | head -1 | sed 's/url=//')
    if [[ -n "$url" ]]; then
      echo ""
      echo "╔═══════════════════════════════════════════════════╗"
      echo "  ngrok tunnel URL:"
      echo "  $url"
      echo ""
      echo "  Use this URL when connecting ChatGPT:"
      echo "  MCP Server URL: ${url}/sse"
      echo "╚═══════════════════════════════════════════════════╝"
      echo ""
      return 0
    fi
    sleep 1
    (( elapsed++ ))
  done

  echo ""
  echo "WARNING: ngrok URL not found after ${NGROK_URL_TIMEOUT}s."
  echo ""
  echo "The tunnel may have failed. Check the log for errors:"
  echo "  cat $LOG_NGROK"
  echo ""
  echo "Common causes:"
  echo "  ERR_NGROK_108 — no authtoken. Run: ngrok config add-authtoken YOUR_TOKEN"
  echo "  ERR_NGROK_3200 — endpoint offline; old URL is no longer valid"
  echo "  Connection error — check your internet connection"
  echo ""
  echo "Get your auth token at: https://dashboard.ngrok.com/authtokens"
  return 1
}

# ── stop ───────────────────────────────────────────────────────────────────────
stop() {
  for pidfile in "$PIDFILE_SERVER" "$PIDFILE_NGROK"; do
    if [[ -f "$pidfile" ]]; then
      local pid
      pid=$(cat "$pidfile")
      if kill "$pid" 2>/dev/null; then
        echo "Stopped pid $pid"
      fi
      rm -f "$pidfile"
    fi
  done
}

# ── status ─────────────────────────────────────────────────────────────────────
status() {
  echo "Server: $([[ -f "$PIDFILE_SERVER" ]] && kill -0 "$(cat "$PIDFILE_SERVER")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_SERVER"))" || echo "STOPPED")"
  echo "ngrok:  $([[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_NGROK"))" || echo "STOPPED")"
  echo ""
  local url
  url=$(grep -oP 'url=https://\S+' "$LOG_NGROK" 2>/dev/null | head -1 | sed 's/url=//')
  if [[ -n "$url" ]]; then
    echo "Tunnel URL: $url"
    echo "MCP endpoint: ${url}/sse"
  else
    echo "Tunnel URL: not found (run start.sh to start)"
  fi
  echo ""
  echo "NEXT STEP: open Claude Code in your project and type /chatgpt-session"
}

# ── main ───────────────────────────────────────────────────────────────────────
case "${1:-start}" in
  start)
    start_server
    sleep 1
    check_ngrok || exit 1
    start_ngrok
    echo ""
    echo "Server is running. Use the tunnel URL above for your ChatGPT MCP connector."
    echo ""
    echo "REQUIRED NEXT STEP:"
    echo "  cd /your/project && claude"
    echo "  Then type: /chatgpt-session"
    echo ""
    echo "The watcher is the other half of this setup."
    echo "Do not skip it — ChatGPT prompts will queue but nothing will execute."
    ;;
  stop)    stop ;;
  status)  status ;;
  restart) stop; sleep 1; bash "$0" start ;;
  *) echo "Usage: bash start.sh [start|stop|status|restart]" ;;
esac
