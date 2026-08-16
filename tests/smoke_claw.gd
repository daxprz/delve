extends SceneTree
## Smoke tests for STO-CHARACTER-084 (Q left claw, E right claw) and
## STO-CHARACTER-085 (a shut claw holds what it closed on).
##   godot --headless -s res://tests/smoke_claw.gd
##
## Two checks carry this file, and both are comparisons:
##
## 1. Working ONE claw must not move the other. Two independent claws
##    is the whole point of two keys — "the claw closed" would pass for
##    a single claw worked by either key.
##
## 2. Caught partway, a claw must be PARTWAY. A claw machine's claw
##    travels; testing only open and shut would pass for one that
##    snaps, and the slow travel is the character of the thing.
##
## Runs offline — no port, so it works while the game is open.

const CHARS := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _me: Node
var _arms: Node
var _mid_left := -1.0
var _box: RigidBody3D


func _open(i: int) -> float:
	return float(_arms.call("claw_openness", i))


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			if _ticks < 10:
				return false
			for i in int(CHARS.count()):
				if String(CHARS.get_def(i)["id"]) == "grabber":
					CHARS.selected_index = i
			_main.call("_begin_game")
			_main.call("_spawn_player", 1)
			return false if _ticks < 40 else _next("found")

		"found":
			_me = _main.get_node_or_null("Players/1")
			_check(_me != null, "a Grabber is in the world")
			if _me == null:
				return _finish()
			_arms = _me.get_node_or_null("MechanicalArms")
			_check(_arms != null and _arms.has_method("claw_openness"),
					"its hands are a claw")
			if _arms == null:
				return _finish()
			_check(bool(_arms.get("claw_mode")),
					"claw mode is on for the Grabber")
			print("[CLAW] starting: left %.2f, right %.2f"
					% [_open(0), _open(1)])
			_check(not bool(_arms.call("claw_shut", 0)),
					"the left claw starts open")
			_check(not bool(_arms.call("claw_shut", 1)),
					"and so does the right")
			_next("close_left")

		"close_left":
			# Q shuts the LEFT claw. The right must not move.
			if _ticks == 1:
				Input.action_press("ability_zip")     # Q
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			# Caught halfway: a claw that snaps is never here.
			if _ticks == 18:
				_mid_left = _open(0)
				return false
			if _ticks < 90:
				return false
			print("[CLAW] after Q: left %.2f (halfway it was %.2f), "
					% [_open(0), _mid_left] + "right %.2f" % _open(1))
			_check(bool(_arms.call("claw_shut", 0)),
					"Q shuts the LEFT claw")
			# THE comparison. Two keys, two claws.
			_check(not bool(_arms.call("claw_shut", 1)),
					"and leaves the right one alone — they are two "
					+ "separate claws, not one")
			_check(_mid_left > 0.1 and _mid_left < 0.85,
					"it TRAVELS: caught halfway it was %.2f, not open or "
					% _mid_left + "shut")
			_next("close_right")

		"close_right":
			if _ticks == 1:
				Input.action_press("toggle_arm_mode")   # E
				return false
			if _ticks == 2:
				Input.action_release("toggle_arm_mode")
				return false
			if _ticks < 90:
				return false
			print("[CLAW] after E: left %.2f, right %.2f"
					% [_open(0), _open(1)])
			_check(bool(_arms.call("claw_shut", 1)), "E shuts the RIGHT claw")
			_check(bool(_arms.call("claw_shut", 0)),
					"and the left one stays shut — each claw keeps its "
					+ "own state")
			_next("open_again")

		"open_again":
			# Pressing again opens it. A toggle, not a hold.
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 90:
				return false
			print("[CLAW] Q again: left %.2f" % _open(0))
			_check(not bool(_arms.call("claw_shut", 0)),
					"pressing Q again OPENS the left claw — it toggles")
			_check(bool(_arms.call("claw_shut", 1)),
					"and the right is still shut")
			_next("grab_setup")

		"grab_setup":
			# STO-CHARACTER-085: shut it on something.
			if _ticks == 1:
				var hand: Node3D = _arms.call("_claw_hand", 0)
				_check(hand != null, "the left claw has a hand")
				if hand == null:
					return _finish()
				_box = RigidBody3D.new()
				_box.name = "Prize"
				_box.add_to_group("grabbable")
				var cs := CollisionShape3D.new()
				var bx := BoxShape3D.new()
				bx.size = Vector3.ONE * 0.4
				cs.shape = bx
				_box.add_child(cs)
				_main.add_child(_box)
				_box.global_position = hand.global_position
				_box.freeze = true          # hold it still to be caught
				return false
			if _ticks < 20:
				return false
			_check(_arms.call("grabbed_body", 0) == null,
					"nothing is held before the claw shuts")
			_next("bite")

		"bite":
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 100:
				return false
			var held = _arms.call("grabbed_body", 0)
			print("[CLAW] after shutting on it: holding %s"
					% (held.name if held != null else "nothing"))
			_check(held == _box,
					"shutting the claw on something CATCHES it")
			_next("let_go")

		"let_go":
			if _ticks == 1:
				Input.action_press("ability_zip")
				return false
			if _ticks == 2:
				Input.action_release("ability_zip")
				return false
			if _ticks < 40:
				return false
			var held = _arms.call("grabbed_body", 0)
			print("[CLAW] after opening: holding %s"
					% (held.name if held != null else "nothing"))
			_check(held == null, "opening it drops what it held")
			_check(is_instance_valid(_box),
					"and the thing still exists afterwards")
			return _finish()
	return false


func _next(phase: String) -> bool:
	_phase = phase
	_ticks = 0
	return false


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
