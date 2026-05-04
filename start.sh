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
NGROK_URL_TIMEOUT=20  # seconds to wait for tunnel URL

# Load .env so NGROK_DOMAIN, PORT, and PROJECT_ROOT are available
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# Portable ngrok lookup — never hardcode a path
NGROK_BIN="$(command -v ngrok || true)"

# ── ngrok preflight ────────────────────────────────────────────────────────────
check_ngrok() {
  if [[ -z "$NGROK_BIN" ]]; then
    echo ""
    echo "ERROR: ngrok is not installed (not found in PATH)."
    echo ""
    echo "ngrok is required so ChatGPT (a cloud service) can reach your local MCP server."
    echo ""
    echo "Install ngrok:"
    echo "  Linux/WSL2:"
    echo "    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \\"
    echo "      | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null"
    echo "    echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' \\"
    echo "      | sudo tee /etc/apt/sources.list.d/ngrok.list"
    echo "    sudo apt update && sudo apt install ngrok"
    echo ""
    echo "  macOS: brew install ngrok"
    echo "  Other: https://ngrok.com/download"
    echo ""
    echo "Then get a free auth token:"
    echo "  1. Sign up at https://ngrok.com (free)"
    echo "  2. Go to https://dashboard.ngrok.com/authtokens"
    echo "  3. Copy your token and run:"
    echo "     ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo ""
    echo "Windows users: do this inside WSL2, not PowerShell."
    echo ""
    return 1
  fi

  # Warn if no authtoken found in known config locations
  local has_token=false
  for cfg in \
    "${HOME}/.config/ngrok/ngrok.yml" \
    "${HOME}/.ngrok2/ngrok.yml" \
    "${XDG_CONFIG_HOME:-}/ngrok/ngrok.yml"; do
    if [[ -f "$cfg" ]] && grep -q "authtoken" "$cfg" 2>/dev/null; then
      has_token=true
      break
    fi
  done

  if ! $has_token; then
    echo ""
    echo "WARNING: ngrok authtoken not detected in config."
    echo "If the tunnel fails to start:"
    echo "  1. Sign up at https://ngrok.com (free)"
    echo "  2. Get your token at https://dashboard.ngrok.com/authtokens"
    echo "  3. Run: ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo ""
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

# ── ngrok URL from local API (works for ngrok v2 and v3) ──────────────────────
get_ngrok_url_from_api() {
  # ngrok exposes a local API on port 4040 — most reliable source of truth
  local url
  url=$(curl -s --connect-timeout 2 http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for t in d.get('tunnels', []):
        u = t.get('public_url', '')
        if u.startswith('https://'):
            print(u)
            break
except:
    pass
" 2>/dev/null)
  echo "$url"
}

# ── ngrok ──────────────────────────────────────────────────────────────────────
start_ngrok() {
  # Prevent duplicate: reuse if already running
  if [[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null; then
    echo "ngrok already running (pid $(cat "$PIDFILE_NGROK")) — getting URL..."
    wait_for_ngrok_url
    return
  fi

  # Kill only the previously tracked ngrok PID — never broad-kill other tunnels
  if [[ -f "$PIDFILE_NGROK" ]]; then
    local old_pid; old_pid=$(cat "$PIDFILE_NGROK")
    kill "$old_pid" 2>/dev/null || true
    rm -f "$PIDFILE_NGROK"
  fi
  sleep 0.3

  # Clear old log
  > "$LOG_NGROK"

  # Use static domain if set in .env (ngrok free static domain or paid reserved domain)
  local ngrok_domain="${NGROK_DOMAIN:-}"
  if [[ -n "$ngrok_domain" ]]; then
    echo "Using static domain: $ngrok_domain"
    nohup "$NGROK_BIN" http --domain="$ngrok_domain" "${PORT:-3333}" >> "$LOG_NGROK" 2>&1 &
  else
    nohup "$NGROK_BIN" http "${PORT:-3333}" >> "$LOG_NGROK" 2>&1 &
  fi
  local ngrok_pid=$!
  echo "$ngrok_pid" > "$PIDFILE_NGROK"
  echo "ngrok starting (pid $ngrok_pid)..."

  # Give it a moment then verify it stayed alive
  sleep 2
  if ! kill -0 "$ngrok_pid" 2>/dev/null; then
    rm -f "$PIDFILE_NGROK"
    echo ""
    echo "ERROR: ngrok process exited immediately."
    echo "Check the log: cat $LOG_NGROK"
    echo ""
    echo "Common cause: missing or invalid authtoken."
    echo "  1. Sign up at https://ngrok.com (free)"
    echo "  2. Get your token at https://dashboard.ngrok.com/authtokens"
    echo "  3. Run: ngrok config add-authtoken YOUR_TOKEN_HERE"
    return 1
  fi

  wait_for_ngrok_url
}

wait_for_ngrok_url() {
  local elapsed=0
  local url=""
  echo "Waiting for tunnel URL..."
  while [[ $elapsed -lt $NGROK_URL_TIMEOUT ]]; do
    url=$(get_ngrok_url_from_api)
    if [[ -n "$url" ]]; then
      print_url "$url"
      return 0
    fi
    sleep 1
    (( elapsed++ ))
  done

  echo ""
  echo "ERROR: No tunnel URL found after ${NGROK_URL_TIMEOUT}s."
  echo ""
  echo "ngrok may have failed to connect. Check the log:"
  echo "  cat $LOG_NGROK"
  echo ""
  echo "Common causes:"
  echo "  ERR_NGROK_108  — no authtoken configured"
  echo "  ERR_NGROK_3200 — old/stale tunnel URL; restart ngrok"
  echo "  No internet    — check your connection"
  echo ""
  echo "To authenticate: ngrok config add-authtoken YOUR_TOKEN_HERE"
  echo "(token at https://dashboard.ngrok.com/authtokens)"
  return 1
}

print_url() {
  local url="$1"
  echo ""
  echo "┌─────────────────────────────────────────────────────┐"
  echo "│  ngrok tunnel URL:                                  │"
  echo "│  $url"
  echo "│                                                     │"
  echo "│  Use this in ChatGPT → Create App:                 │"
  echo "│  MCP Server URL: ${url}/sse"
  echo "└─────────────────────────────────────────────────────┘"
  echo ""
}

# ── status ─────────────────────────────────────────────────────────────────────
status() {
  echo "Server: $([[ -f "$PIDFILE_SERVER" ]] && kill -0 "$(cat "$PIDFILE_SERVER")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_SERVER"))" || echo "STOPPED")"
  echo "ngrok:  $([[ -f "$PIDFILE_NGROK" ]] && kill -0 "$(cat "$PIDFILE_NGROK")" 2>/dev/null && echo "RUNNING (pid $(cat "$PIDFILE_NGROK"))" || echo "STOPPED")"
  local url
  url=$(get_ngrok_url_from_api)
  if [[ -n "$url" ]]; then
    echo "Tunnel: $url"
    echo "MCP endpoint: ${url}/sse"
  else
    echo "Tunnel: not found"
  fi
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

# ── main ───────────────────────────────────────────────────────────────────────
case "${1:-start}" in
  start)
    start_server
    sleep 1
    check_ngrok || exit 1
    start_ngrok || exit 1
    echo "MCP server and tunnel are running."
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
