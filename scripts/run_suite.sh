#!/usr/bin/env bash
# Run every headless smoke test in tests/ and print one summary line.
#
#   scripts/run_suite.sh                 # everything
#   scripts/run_suite.sh clamber crawler # only tests matching these names
#   TIMEOUT=240 scripts/run_suite.sh     # longer per-test budget
#
# Exit status is the number of FAILING tests, so CI can gate on it.
#
# Tests that need the multiplayer port cannot run while the operator's
# game is hosting. Those are counted as SKIPPED rather than passed, and
# named in the summary — a skipped test that quietly counts as green is
# how two broken tests shipped in v0.1.9.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 99

TIMEOUT="${TIMEOUT:-180}"
LOG_DIR="${LOG_DIR:-/tmp/delve-suite}"
mkdir -p "$LOG_DIR"

pass=0; fail=0; skip=0
failed=(); skipped=()

# ENet binds UDP, so a TCP-only check reports the port free while the
# game is plainly holding it. Look at UDP.
if ss -lunp 2>/dev/null | grep -q ':7777'; then
	echo "WARNING: something already holds 7777/udp (the game is open)."
	echo "         Multiplayer tests will SKIP, not run. Close it to verify them."
	echo
fi

for path in tests/smoke_*.gd; do
	name="$(basename "$path" .gd)"

	# Name filter: if arguments were given, the test must match one.
	if [ "$#" -gt 0 ]; then
		match=0
		for want in "$@"; do
			case "$name" in *"$want"*) match=1 ;; esac
		done
		[ "$match" -eq 1 ] || continue
	fi

	# Two-instance tests come in pairs. A `_client` half dials a host
	# that only exists when its partner is running, so launching it on
	# its own is not a failing test — it is a test that was never
	# started properly. Skip the client half here and drive the whole
	# pair from the `_host` half instead.
	case "$name" in *_client) continue ;; esac

	out="$LOG_DIR/$name.log"
	case "$name" in
		*_host)
			pair="${name#smoke_}"; pair="${pair%_host}"
			if [ -f "tests/smoke_${pair}_client.gd" ]; then
				timeout "$TIMEOUT" scripts/run_mp_test.sh "$pair" >"$out" 2>&1
				status=$?
				name="$name+client"
			else
				timeout "$TIMEOUT" godot --headless --path . -s "res://$path" >"$out" 2>&1
				status=$?
			fi
			;;
		*)
			timeout "$TIMEOUT" godot --headless --path . -s "res://$path" >"$out" 2>&1
			status=$?
			;;
	esac

	# A pass is a pass — check it FIRST. Plenty of tests log the port
	# error harmlessly because they never needed a server; counting
	# those as unverified is noise that trains you to ignore the skip
	# list, which is the one list here that must stay worth reading.
	if grep -q "^RESULT: PASS\|MP TEST .*: PASS" "$out"; then
		pass=$((pass + 1))
		printf 'ok    %s\n' "$name"
	# The real message Godot emits when the operator's game already
	# holds the multiplayer port. Note it is UDP (ENet), so `ss -ltn`
	# shows the port as free — trust this string, not a port scan.
	elif grep -q "create_server(7777) failed\|Couldn't create an ENet host" "$out"; then
		skip=$((skip + 1)); skipped+=("$name")
		printf 'SKIP  %s (multiplayer port busy)\n' "$name"
	elif [ "$status" -eq 124 ]; then
		fail=$((fail + 1)); failed+=("$name(timeout)")
		printf 'FAIL  %s (timed out after %ss)\n' "$name" "$TIMEOUT"
	else
		fail=$((fail + 1)); failed+=("$name")
		printf 'FAIL  %s -- %s\n' "$name" "$out"
	fi
done

echo
echo "SUITE: pass=$pass fail=$fail skipped(port-in-use)=$skip"
[ "${#failed[@]}"  -gt 0 ] && echo "FAILED:  ${failed[*]}"
[ "${#skipped[@]}" -gt 0 ] && echo "SKIPPED: ${skipped[*]}"
[ "$skip" -gt 0 ] && echo "NOTE: skipped tests are NOT verified. Close the game and re-run before releasing."
exit "$fail"
