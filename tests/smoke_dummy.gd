extends SceneTree
## Smoke test for STO-ENEMIES-029 — the practice dummy.
##   godot --headless -s res://tests/smoke_dummy.gd
##
## The dummy is a stand-in second player, so what is worth checking is
## not that it exists but that the REST of delve treats it like one. A
## dummy that stands in the world and that nothing else recognises
## would look finished and test nothing.
##
## The load-bearing check is that an enemy attacks it unprompted. That
## is the one nothing else in the suite covers, and the one that breaks
## silently if the dummy ever stops joining the players group.

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _dummy: Node3D
var _start := Vector3.ZERO
var _hp_before := 0.0
var _saw_enemy_damage := false


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 5:
				if _ticks == 1:
					_main = load("res://scenes/main.tscn").instantiate()
					root.add_child(_main)
				return false
			var dummies := root.get_tree().get_nodes_in_group("dummies")
			_check(dummies.size() > 0, "a dummy is standing in the world")
			if dummies.is_empty():
				return _finish()
			_dummy = dummies[0]
			# It has to BE a player as far as everything else is
			# concerned — this is the whole design decision.
			_check(_dummy.is_in_group("players"),
					"the dummy counts as a player to the rest of delve")
			_check(_dummy.has_method("hurt_by_enemy"),
					"it answers hurt_by_enemy, like a player")
			_check(_dummy.has_method("health") and _dummy.has_method("max_health"),
					"it reports health like a player")
			_check(float(_dummy.call("health")) > 0.0,
					"it starts with health (%.0f)" % float(_dummy.call("health")))
			_next("settle")

		"settle":
			# Let gravity put it on the floor before recording home.
			if _ticks < 40:
				return false
			_start = _dummy.global_position
			print("[DUMMY] settled at %.2f, %.2f, %.2f"
					% [_start.x, _start.y, _start.z])
			_check(_start.y > -5.0, "it does not fall out of the world")
			_next("stays_put")

		"stays_put":
			# "It just stands there" is the operator's spec, so it is
			# worth asserting rather than assuming: an AI added later
			# by accident should fail here loudly.
			if _ticks < 90:
				return false
			var drift := _dummy.global_position.distance_to(_start)
			print("[DUMMY] drifted %.3f m in 90 ticks" % drift)
			_check(drift < 0.1, "it never moves on its own (%.3f m)" % drift)
			_next("hurt")

		"hurt":
			_hp_before = float(_dummy.call("health"))
			_dummy.call("hurt_by_enemy", 15.0)
			var after := float(_dummy.call("health"))
			_check(after < _hp_before,
					"hitting it takes health off (%.0f -> %.0f)"
					% [_hp_before, after])
			_next("enemy")

		"enemy":
			# The real check: an enemy goes for it with no prompting.
			# Nothing was told about dummies — it works only because
			# the dummy is in the players group.
			if _ticks == 1:
				var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
				e.name = "Hunter"
				_main.get_node("Enemies").add_child(e)
				e.global_position = _dummy.global_position + Vector3(2.0, 0.0, 0.0)
				_hp_before = float(_dummy.call("health"))
				return false
			if float(_dummy.call("health")) < _hp_before:
				_saw_enemy_damage = true
			if _ticks < 260 and not _saw_enemy_damage:
				return false
			print("[DUMMY] health %.0f after enemy (was %.0f)"
					% [float(_dummy.call("health")), _hp_before])
			_check(_saw_enemy_damage,
					"an enemy attacks the dummy unprompted")
			_next("revive")

		"revive":
			# Practice must not run out of dummy.
			if _ticks == 1:
				_dummy.call("take_damage", 9999.0)
				return false
			if _ticks == 2:
				_check(bool(_dummy.call("is_down")),
						"beaten to nothing, it goes down")
				return false
			if _ticks < 150:
				return false
			_check(not bool(_dummy.call("is_down")),
					"and it gets back up so you can carry on")
			_check(float(_dummy.call("health")) > 50.0,
					"back up with health again (%.0f)"
					% float(_dummy.call("health")))
			# Added because the first version silently failed it. The
			# dummy recorded its home in _ready(), before the spawn
			# point had been applied, so it revived at the world origin
			# — metres from where it had been standing all along. Every
			# other check in this phase passed regardless: health is
			# not position, and checking one proves nothing about the
			# other.
			var moved := _dummy.global_position.distance_to(_start)
			print("[DUMMY] revived %.2f m from where it stood" % moved)
			_check(moved < 0.5,
					"and gets up where it was standing, not at the world "
					+ "origin (%.2f m away)" % moved)
			return _finish()
	return false


func _next(phase: String) -> void:
	_phase = phase
	_ticks = 0


func _finish() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
