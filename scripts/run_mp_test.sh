#!/usr/bin/env bash
# Two-instance multiplayer smoke test (STO-CORE-003).
# Launches a headless host + headless client on localhost:7777 and
# aggregates their PASS/FAIL output. Exit 0 = both sides passed.
#
# Usage:  scripts/run_mp_test.sh [pair]
#   pair defaults to "mp"  -> tests/smoke_mp_host.gd   + smoke_mp_client.gd
#   e.g. "name"            -> tests/smoke_name_host.gd + smoke_name_client.gd
#
# Some things can only be proven with two real instances: that a value
# reaches the OTHER machine, rather than merely looking right on your
# own screen. Every multiplayer bug in delve so far was found this way.
set -u

PAIR="${1:-mp}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_TEST="res://tests/smoke_${PAIR}_host.gd"
CLIENT_TEST="res://tests/smoke_${PAIR}_client.gd"
HOST_LOG="/tmp/delve_${PAIR}_host.log"
CLIENT_LOG="/tmp/delve_${PAIR}_client.log"

for f in "tests/smoke_${PAIR}_host.gd" "tests/smoke_${PAIR}_client.gd"; do
    if [ ! -f "$DIR/$f" ]; then
        echo "no such test pair: $f" >&2
        exit 2
    fi
done

godot --headless --path "$DIR" -s "$HOST_TEST" >"$HOST_LOG" 2>&1 &
HOST_PID=$!

sleep 1  # let the server bind before the client dials

godot --headless --path "$DIR" -s "$CLIENT_TEST" >"$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!

wait "$CLIENT_PID"; CLIENT_RC=$?
wait "$HOST_PID";   HOST_RC=$?

echo "--- host ---"
grep -E "PASS|FAIL|RESULT|ERROR" "$HOST_LOG"
echo "--- client ---"
grep -E "PASS|FAIL|RESULT|ERROR" "$CLIENT_LOG"

if [ "$HOST_RC" -eq 0 ] && [ "$CLIENT_RC" -eq 0 ]; then
    echo "MP TEST ($PAIR): PASS"
    exit 0
else
    echo "MP TEST ($PAIR): FAIL (host=$HOST_RC client=$CLIENT_RC)"
    exit 1
fi
