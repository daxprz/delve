extends SceneTree
## Smoke test for STO-CHARACTER-056 — C and G do nothing.
##   godot --headless -s res://tests/smoke_dead_keys.gd
##
## G was the throw; RMB does that now and better
## (STO-CHARACTER-055). C was block, parry and dodge-roll, dropped by
## the operator knowing what it costs: since STO-ENEMIES-011 enemies
## actually attack, this leaves no defence but footwork.
##
## Presses the real keys, because "the code path is gone" and "the key
## does nothing" are different claims and only the second was asked for.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _walk_from := Vector3.ZERO


func _spawn(char_index: int) -> CharacterBody3D:
	for c in _main.get_node("Players").get_children():
		c.free()
	CharacterDB.selected_index = char_index
	var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	p.name = "1"
	_main.get_node("Players").add_child(p)
	return p


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			_player = _spawn(0)                    # Grabber: block/parry/throw
			_next("grabber")
		"grabber":
			if _ticks < 4:
				return false
			if _ticks == 4:
				Input.action_press("ability_guard")     # C
				Input.action_press("ability_throw")     # G
				return false
			if _ticks < 12:
				return false
			# C must not put us in a guard.
			_check(not bool(_player.call("is_blocking")),
					"holding C does not block")
			# G must not pick anything up.
			_check(_player.call("held_object") == null,
					"pressing G does not pick anything up")
			# And a hit must cost FULL damage — the point of the trade.
			_player.call("set_health", 100.0)
			var hp_before := float(_player.call("health"))
			_player.call("hurt_by_enemy", 12.0)
			var lost := hp_before - float(_player.call("health"))
			_check(lost > 11.0,
					"an enemy hit costs full damage with C held (%.1f)" % lost)
			Input.action_release("ability_guard")
			Input.action_release("ability_throw")
			_next("runner")
		"runner":
			if _ticks < 2:
				return false
			if _ticks == 2:
				_player = _spawn(1)                # Runner: dodge roll
				return false
			if _ticks < 8:
				return false
			if _ticks == 8:
				Input.action_press("ability_guard")     # C
				return false
			if _ticks < 16:
				return false
			_check(not bool(_player.call("is_rolling")),
					"pressing C does not start a dodge roll")
			_player.call("set_health", 100.0)
			var hp2 := float(_player.call("health"))
			_player.call("hurt_by_enemy", 12.0)
			var lost2 := hp2 - float(_player.call("health"))
			_check(lost2 > 11.0,
					"the Runner takes full damage too (%.1f)" % lost2)
			Input.action_release("ability_guard")
			_next("others")
		"others":
			# Nothing ELSE on the keyboard may have changed.
			if _ticks < 4:
				return false
			if _ticks == 4:
				_walk_from = _player.global_position
				Input.action_press("move_forward")
				return false
			if _ticks < 40:
				return false
			Input.action_release("move_forward")
			var walked := _player.global_position.distance_to(_walk_from)
			_check(walked > 0.5, "W still moves you (%.2f m)" % walked)
			# The abilities themselves are only unhooked, not destroyed,
			# so they can be put on another key with one line.
			_check(_player.has_method("do_dodge")
							and _player.has_method("do_parry")
							and _player.has_method("do_throw"),
					"the abilities still exist in code, just unbound")
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
