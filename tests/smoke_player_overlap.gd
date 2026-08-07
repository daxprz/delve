extends SceneTree
## Regression test for STO-CORE-004 — the infinite-launch bug.
##   godot --headless -s res://tests/smoke_player_overlap.gd
##
## Found by running two real instances: both players spawned on the
## same marker, and instead of settling they climbed past 2.5 km,
## still accelerating. A remote player's position comes from the
## network sync so it cannot be pushed aside — each instance shoved
## its OWN player up to escape, synced the higher position, and shoved
## the other higher again.
##
## This test recreates the trigger directly — two players placed
## exactly on top of each other — and requires them to stay put. It
## deliberately does NOT test spawn spreading: spreading only avoids
## the usual trigger, while walking into someone would set it off just
## the same.

const SETTLE := 40
const WATCH := 150

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _a: CharacterBody3D
var _b: CharacterBody3D
var _start_y := 0.0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(60, 1, 60)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var scene: PackedScene = load("res://scenes/player.tscn")
			_a = scene.instantiate()
			_a.name = "1"
			_a.position = Vector3(0, 1, 0)
			root.add_child(_a)
			# EXACTLY on top of the first one — the fatal geometry,
			# because the only way out is straight up.
			_b = scene.instantiate()
			_b.name = "2"
			_b.position = Vector3(0, 1, 0)
			root.add_child(_b)
			_next("settle")
		"settle":
			if _ticks < SETTLE:
				return false
			_start_y = maxf(_a.global_position.y, _b.global_position.y)
			_check(_start_y < 2.0,
					"overlapping players settle instead of launching (y=%.2f)"
					% _start_y)
			_next("watch")
		"watch":
			if _ticks < WATCH:
				return false
			var high := maxf(_a.global_position.y, _b.global_position.y)
			_check(high < 2.0,
					"they stay down over time (y=%.2f)" % high)
			_check(high <= _start_y + 0.5,
					"no runaway climb (%.2f m -> %.2f m)" % [_start_y, high])
			_check(_a.global_position.y < 1.5 and _b.global_position.y < 1.5,
					"neither player is riding on the other (%.2f / %.2f)"
					% [_a.global_position.y, _b.global_position.y])
			# They still collide with the WORLD — the exception is only
			# between players, not a blanket "ignore everything".
			_check(_a.is_on_floor() or _b.is_on_floor(),
					"players still stand on the ground")
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
