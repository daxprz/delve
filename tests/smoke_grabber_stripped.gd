extends SceneTree
## Smoke test for STO-CHARACTER-083 — the Grabber has nothing left.
##   godot --headless -s res://tests/smoke_grabber_stripped.gd
##
## This presses the KEYS. That distinction is the whole test.
##
## `smoke_abilities` calls `do_throw()`, `do_zip()` and friends
## directly, so it passes whether or not the Grabber can still reach
## them — it tests that the functions work, never that the character is
## allowed to use them. Removing every ability from the Grabber changed
## nothing about that test, which is exactly how a removal could look
## finished and not be.
##
## Driving the function is not driving the feature. So: hold the old
## keys, and check the Grabber does not do the old things.
##
## Runs offline — no port needed, so it works while the game is open.

const CHARS := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _me: Node
var _start := Vector3.ZERO


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
			return false if _ticks < 40 else _next("who")

		"who":
			_me = _main.get_node_or_null("Players/1")
			_check(_me != null, "a Grabber is in the world")
			if _me == null:
				return _finish()
			_check(String(_me.call("character_id")) == "grabber",
					"and it really is the Grabber (%s)"
					% String(_me.call("character_id")))
			# The registry is the source of truth for what it can do.
			var def: Dictionary = CHARS.get_def(CHARS.selected_index)
			var abilities: Array = def.get("abilities", [])
			print("[STRIP] the Grabber's abilities: %s" % str(abilities))
			_check(abilities.is_empty(),
					"it has NO abilities left (%d)" % abilities.size())
			_check(bool(def.get("arms", false)),
					"but it keeps its mechanical arms — the claw needs them")
			_next("keys")

		"keys":
			# Hold every key the old abilities used, all at once, for a
			# good while. Nothing should happen.
			if _ticks == 1:
				_start = (_me as Node3D).global_position
				for a in ["ability_zip", "ability_throw", "ability_pull",
						"ability_guard", "toggle_arm_mode"]:
					if InputMap.has_action(a):
						Input.action_press(a)
				return false
			if _ticks < 90:
				return false
			for a in ["ability_zip", "ability_throw", "ability_pull",
					"ability_guard", "toggle_arm_mode"]:
				if InputMap.has_action(a):
					Input.action_release(a)

			var moved: float = _start.distance_to(
					(_me as Node3D).global_position)
			print("[STRIP] after holding every old ability key for 90 "
					+ "ticks: moved %.2f m" % moved)
			# Zip would have hurled it across the map.
			_check(moved < 2.0,
					"the zip key does not fling it anywhere (%.2f m)"
					% moved)
			if _me.has_method("is_blocking"):
				_check(not bool(_me.call("is_blocking")),
						"the guard key does not put it in a block")
			if _me.has_method("is_holding"):
				_check(not bool(_me.call("is_holding")),
						"the throw key does not make it grab anything")
			_next("still_works")

		"still_works":
			# Removal must be from the GRABBER, not from the game.
			var runner := -1
			for i in int(CHARS.count()):
				if String(CHARS.get_def(i)["id"]) == "runner":
					runner = i
			var r: Dictionary = CHARS.get_def(runner)
			print("[STRIP] the Runner still has: %s"
					% str(r.get("abilities", [])))
			_check(not (r.get("abilities", []) as Array).is_empty(),
					"other characters kept their abilities — this was a "
					+ "removal from the Grabber, not from the game")
			# And the arms themselves survive.
			var arms := _me.get_node_or_null("MechanicalArms")
			_check(arms != null,
					"the Grabber still has its arms to make a claw from")
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
