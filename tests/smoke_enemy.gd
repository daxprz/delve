extends SceneTree
## Headless smoke test for STO-ENEMIES-001 (follower enemy).
## Run with:  godot --headless -s res://tests/smoke_enemy.gd
##
## Verifies:
##   - enemies spawn in the world
##   - an enemy walks TOWARD the player (gets closer over time)
##   - apply_knockback shoves it back (it moves away briefly)
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const CHASE := 60
const KNOCK := 10

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _enemy: CharacterBody3D
var _d_start := 0.0
var _d_before_knock := 0.0


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false
	_pass("%d enemies spawned" % enemies.get_child_count())
	_enemy = enemies.get_child(0) as CharacterBody3D

	# Put the player at the origin and the enemy out in the open.
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_enemy.global_position = Vector3(6.0, 1.0, 6.0)
	_d_start = _flat_dist(_enemy, _player)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "chase"
		"chase":
			_frames += 1
			if _frames >= CHASE:
				var d := _flat_dist(_enemy, _player)
				if d < _d_start - 1.0:
					_pass("enemy followed the player (%.1f m -> %.1f m)"
							% [_d_start, d])
				else:
					_fail("enemy did not approach (%.1f m -> %.1f m)"
							% [_d_start, d])
				# Now punch it away from the player.
				_d_before_knock = _flat_dist(_enemy, _player)
				var away := (_enemy.global_position - _player.global_position)
				away.y = 0.0
				_enemy.apply_knockback(away.normalized() * 8.0)
				_frames = 0
				_phase = "knock"
		"knock":
			_frames += 1
			if _frames >= KNOCK:
				var d := _flat_dist(_enemy, _player)
				if d > _d_before_knock + 0.3:
					_pass("knockback shoved the enemy back (%.1f m -> %.1f m)"
							% [_d_before_knock, d])
				else:
					_fail("knockback did nothing (%.1f m -> %.1f m)"
							% [_d_before_knock, d])
				return _done()
	return false


func _flat_dist(a: Node3D, b: Node3D) -> float:
	var d := a.global_position - b.global_position
	d.y = 0.0
	return d.length()


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
