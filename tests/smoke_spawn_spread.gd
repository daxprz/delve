extends SceneTree
## Regression test for STO-CORE-004: two players must not spawn inside
## each other. Non-hosted (the spawn maths is pure).
##   godot --headless -s res://tests/smoke_spawn_spread.gd
##
## The bug this guards: everyone spawned on the same marker, the
## capsules overlapped exactly, and because a remote player's position
## comes from the network sync it cannot be pushed aside — so each
## instance shoved its OWN player upward to escape, synced the higher
## position, and shoved the other higher again. Both players climbed
## past 2.5 km, still accelerating.

const CAPSULE_DIAMETER := 0.8

var _failures := 0
var _ticks := 0
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	_check(_main.has_method("spawn_position_for_peer"),
			"spawn position is derived per peer")

	var host: Vector3 = _main.call("spawn_position_for_peer", 1)
	var peers := [1, 4242, 95487311, 1908778214, 777, 31337]
	var spots: Array = []
	for id in peers:
		spots.append(_main.call("spawn_position_for_peer", id))

	# The host keeps the marker itself.
	_check(host == _main.get_node("SpawnPoint").position,
			"the host spawns on the marker")

	# Spreading is a NICETY, not the safety net: it stops players
	# materialising inside each other, but two independent peers
	# hashing to nearby spots is always possible, and walking into
	# someone would overlap them anyway. The actual guarantee that
	# nobody gets launched lives in smoke_player_overlap.gd (players
	# do not collide with each other at all).
	var close := 0
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			if (spots[i] as Vector3).distance_to(spots[j]) < CAPSULE_DIAMETER:
				close += 1
	_check(close <= 1,
			"arrivals are generally spread out (%d close pairs of %d)"
			% [close, spots.size() * (spots.size() - 1) / 2])

	# Deterministic: the same peer always gets the same spot, which is
	# what lets host and client agree without exchanging messages.
	var again: Vector3 = _main.call("spawn_position_for_peer", 95487311)
	_check(again == spots[2], "the same peer always gets the same spot")

	# Spots stay near the marker — spreading must not fling anyone off.
	for s in spots:
		_check((s as Vector3).distance_to(host) < 4.0,
				"spawn stays near the marker (%.1f m)"
				% (s as Vector3).distance_to(host))

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
