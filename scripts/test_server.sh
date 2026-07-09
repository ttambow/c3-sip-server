#!/usr/bin/env bash
set -euo pipefail

SERVER_BIN="build/c3-sip-server"
SERVER_LOG="/tmp/c3-sip-server.log"
SERVER_PID=""
SERVER_PORT=5060
DATE="$(date +%s)"

function build()
{
  c3c build
}

function check()
{
  if ! pgrep -f "$SERVER_BIN" > /dev/null 2>&1; then
    echo "Error! The C3 SIP Server is not running!"

    return 1
  fi

  echo "Server process: $(pgrep -a -f "$SERVER_BIN")"

  if ss -tlnp 2>/dev/null | grep -q ":$SERVER_PORT "; then
    echo "Port $SERVER_PORT is listening"
  else
    echo "Error! Port $SERVER_PORT is not listening"

    return 1
  fi
}

function cleanup()
{
  rm $SERVER_LOG
}

function construct_request()
{
  local branch="z9hG4bK-$DATE"
  local call_id="test-call-$DATE@127.0.0.1"
  local request_type="${1:-INVITE}"
  local tag="$DATE"

  case "$request_type" in
    INVITE)
      echo -ne "INVITE sip:bob@127.0.0.1 SIP/2.0\r\nVia: SIP/2.0/TCP 127.0.0.1:5061;branch=$branch\r\nFrom: <sip:alice@127.0.0.1>;tag=$tag\r\nTo: <sip:bob@127.0.0.1>\r\nCall-ID: $call_id\r\nCSeq: 1 INVITE\r\nContact: <sip:alice@127.0.0.1:5061>\r\nContent-Type: application/sdp\r\nContent-Length: 0\r\n\r\n"
      ;;
    ACK)
      echo -ne "ACK sip:bob@127.0.0.1 SIP/2.0\r\nVia: SIP/2.0/TCP 127.0.0.1:5061;branch=$branch\r\nFrom: <sip:alice@127.0.0.1>;tag=$tag\r\nTo: <sip:bob@127.0.0.1>\r\nCall-ID: $call_id\r\nCSeq: 1 ACK\r\nContact: <sip:alice@127.0.0.1:5061>\r\nContent-Length: 0\r\n\r\n"
      ;;
    BYE)
      echo -ne "BYE sip:bob@127.0.0.1 SIP/2.0\r\nVia: SIP/2.0/TCP 127.0.0.1:5061;branch=$branch\r\nFrom: <sip:alice@127.0.0.1>;tag=$tag\r\nTo: <sip:bob@127.0.0.1>\r\nCall-ID: $call_id\r\nCSeq: 2 BYE\r\nContact: <sip:alice@127.0.0.1:5061>\r\nContent-Length: 0\r\n\r\n"
      ;;
    REGISTER)
      echo -ne "REGISTER sip:127.0.0.1 SIP/2.0\r\nVia: SIP/2.0/TCP 127.0.0.1:5061;branch=$branch\r\nFrom: <sip:alice@127.0.0.1>;tag=$tag\r\nTo: <sip:alice@127.0.0.1>\r\nCall-ID: $call_id\r\nCSeq: 1 REGISTER\r\nContact: <sip:alice@127.0.0.1:5061>\r\nContent-Length: 0\r\n\r\n"
      ;;
    OPTIONS)
      echo -ne "OPTIONS sip:127.0.0.1 SIP/2.0\r\nVia: SIP/2.0/TCP 127.0.0.1:5061;branch=$branch\r\nFrom: <sip:alice@127.0.0.1>;tag=$tag\r\nTo: <sip:127.0.0.1>\r\nCall-ID: $call_id\r\nCSeq: 1 OPTIONS\r\nContact: <sip:alice@127.0.0.1:5061>\r\nContent-Length: 0\r\n\r\n"
      ;;
    *)
      echo "Unknown request type: $request_type" >&2

      return 1
      ;;
  esac
}

function main()
{
  build
  run
  check
  send_request
  stop
}

function run()
{
  if pgrep -f "$SERVER_BIN" > /dev/null 2>&1; then
    echo "Server already running"

    SERVER_PID=$(pgrep -f "$SERVER_BIN")

    return
  fi

  nohup "$SERVER_BIN" > $SERVER_LOG 2>&1 &

  SERVER_PID=$!

  sleep 1

  if kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Server started (PID: $SERVER_PID)"
  else
    echo "Error! Server failed to start"

    exit 1
  fi
}

function send_request()
{
  local request_type="${1:-INVITE}"

  echo -e "Sending SIP $request_type...\n"

  construct_request "$request_type" | nc -w 3 127.0.0.1 $SERVER_PORT

  echo -e "Server log:\n"

  cat $SERVER_LOG
}

function stop()
{
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true

    echo "Server stopped"
  else
    pkill -f "$SERVER_BIN" 2>/dev/null || true

    echo "Server stopped"
  fi

  cleanup

  SERVER_PID=""
}

function usage()
{
  echo "Usage: $0 {build|run|check|stop|invite|request|all}"
  exit 1
}

if [ $# -eq 0 ]; then
  main
else
  case "${1:-all}" in
    all)     main ;;
    build)   build ;;
    check)   check ;;
    invite|request)  send_request "${2:-INVITE}" ;;
    run)     run ;;
    stop)    stop ;;
    *)       usage ;;
  esac
fi
