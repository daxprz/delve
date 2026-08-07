#!/usr/bin/env bash
# Send an RCON command to a running delve instance.
#   scripts/rcon.sh status
#   scripts/rcon.sh debug log enemy/ai
#   scripts/rcon.sh -p 10000 status     # talk to a second instance
set -u

PORT=9999
if [ "${1:-}" = "-p" ]; then
    PORT="$2"
    shift 2
fi

if [ $# -eq 0 ]; then
    echo "usage: $0 [-p port] <command...>" >&2
    exit 2
fi

echo "$*" | nc -w2 localhost "$PORT"
