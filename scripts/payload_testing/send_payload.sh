#!/usr/bin/env bash
set -euo pipefail

METHOD="${1:-}"
PAYLOAD_DIR="$(dirname "$0")/payloads"
PORT="${3:-5060}"
SERVER="${2:-127.0.0.1}"

function usage()
{
  echo "Usage: $0 <method> [server] [port]"
  echo -e "\nAvailable methods:"

  for f in "$PAYLOAD_DIR"/*.txt; do
    name="$(basename "$f" .txt)"

    echo "  $name"
  done

  echo -e "\nExamples:"
  echo "  $0 INVITE"
  echo "  $0 BYE 192.168.1.10"
  echo "  $0 REGISTER 192.168.1.10 5060"

  exit 1
}

function main()
{
  if [ -z "$METHOD" ]; then
    usage
  fi

  PAYLOAD_FILE="$PAYLOAD_DIR/${METHOD}.txt"
  if [ ! -f "$PAYLOAD_FILE" ]; then
    echo "Error: no payload for '$METHOD'"
    echo "Available: "

    find "$PAYLOAD_DIR"/*.txt | while read -r f; do basename "$f" .txt; done

    exit 1
  fi

  echo -e "=== Sending $METHOD to $SERVER:$PORT ===\n"

  # Converting LF -> CRLF ensures SIP-compliant line endings
  {
    while IFS= read -r line; do
      printf '%s\r\n' "$line"
    done < "$PAYLOAD_FILE"

    # TODO is there a better way to do this? feels hacky...
    if [ "$(tail -c 1 "$PAYLOAD_FILE" | wc -l)" -eq 0 ]; then
      printf '\r\n'
    fi
  } | nc -w 3 "$SERVER" "$PORT"

  RC=$?

  echo -e "\n=== Done (exit code: $RC) ==="
}

main