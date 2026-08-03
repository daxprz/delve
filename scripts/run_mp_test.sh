#!/usr/bin/env bash
# Two-instance multiplayer smoke test (STO-CORE-003).
# Launches a headless host + headless client on localhost:7777 and
# aggregates their PASS/FAIL output. Exit 0 = both sides passed.
set -u

DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_LOG=/tmp/delve_mp_host.log
CLIENT_LOG=/tmp/delve_mp_client.log

godot --headless --path "$DIR" -s res://tests/smoke_mp_host.gd >"$HOST_LOG" 2>&1 &
HOST_PID=$!

sleep 1  # let the server bind before the client dials

godot --headless --path "$DIR" -s res://tests/smoke_mp_client.gd >"$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!

wait "$CLIENT_PID"; CLIENT_RC=$?
wait "$HOST_PID";   HOST_RC=$?

echo "--- host ---"
grep -E "PASS|FAIL|RESULT|ERROR" "$HOST_LOG"
echo "--- client ---"
grep -E "PASS|FAIL|RESULT|ERROR" "$CLIENT_LOG"

if [ "$HOST_RC" -eq 0 ] && [ "$CLIENT_RC" -eq 0 ]; then
    echo "MP TEST: PASS"
    exit 0
else
    echo "MP TEST: FAIL (host=$HOST_RC client=$CLIENT_RC)"
    exit 1
fi
