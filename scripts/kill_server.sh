#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN="c3-sip-server"
SERVER_PORT=5060

function main()
{
  echo "Killing server on port $SERVER_PORT..."
  try_fuser || try_pkill || try_kill_from_ss || try_force || echo "Nothing to kill"
}

function try_force()
{
  echo "Trying kill -9 from pgrep..."

  local pid
  pid=$(pgrep -f "$SERVER_BIN" 2>/dev/null || true)

  if [ -n "$pid" ]; then
    echo "  Killing PID $pid"

    kill -9 "$pid" 2>/dev/null || true

    sleep 0.5

    if ! pgrep -f "$SERVER_BIN" > /dev/null 2>&1; then
      echo "  Done"

      return 0
    fi
  fi
  return 1
}

function try_fuser()
{
  echo "Trying fuser -k $SERVER_PORT/tcp..."
  if fuser -k "$SERVER_PORT/tcp" 2>/dev/null; then
    sleep 0.5

    if ! ss -tlnp | grep -q ":$SERVER_PORT "; then
      echo "  Done (port $SERVER_PORT freed)"

      return 0
    fi
  fi
  return 1
}

function try_kill_from_ss()
{
  echo "Trying ss + kill..."

  local pid
  pid=$(ss -tlnp | grep ":$SERVER_PORT " | sed -n 's/.*users:((".*",pid=\([0-9]*\),.*/\1/p')

  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true

    sleep 0.5

    if ! ss -tlnp | grep -q ":$SERVER_PORT "; then
      echo "  Done (PID $pid killed)"

      return 0
    fi
  fi
  return 1
}

function try_pkill()
{
  echo "Trying pkill -f $SERVER_BIN..."
  if pkill -f "$SERVER_BIN" 2>/dev/null; then
    sleep 0.5

    if ! pgrep -f "$SERVER_BIN" > /dev/null 2>&1; then
      echo "  Done (process killed)"

      return 0
    fi
  fi
  return 1
}

main