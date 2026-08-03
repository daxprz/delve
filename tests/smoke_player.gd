extends SceneTree
## Headless smoke test for STO-CORE-002 (first seed of delve's test
## infrastructure — run with:
##   godot --headless -s res://tests/smoke_player.gd
##
## Loads main.tscn and drives the Player through phases:
##   LAND    — player spawns at y=1, must come to rest on the floor
##   MOVE    — inject move_forward, player must travel forward (-Z)
##   JUMP    — inject jump, player must leave the floor, then re-land
## Prints one PASS/FAIL line per check; exits non-zero on any FAIL.

## Phase lengths in PHYSICS ticks (60/s) — process frames run faster
## than physics in headless mode, so phases must be timed on ticks.
const LAND_FRAMES := 120
const MOVE_FRAMES := 60
const JUMP_FRAMES := 90

var _frames := 0
var _phase := "setup"
var _failures := 0
var _main: Node
var _player: CharacterBody3D
var _move_start_z := 0.0
var _jump_peak_y := 0.0


func _setup() -> bool:
	# Must run on the first physics tick, NOT in _initialize():
	# autoloads join the tree (and child _ready fires) only after
	# _initialize returns. See agent memory: godot-headless-testing.
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("main.tscn failed to load")
		return false
	_main = packed.instantiate()
	root.add_child(_main)
	# Players spawn on host/join since STO-CORE-003 — host to get one.
	_main.host_game()
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player node at Players/1 after host_game()")
		return false
	return true


func _physics_process(_delta: float) -> bool:
	if _phase == "setup":
		if not _setup():
			_finish()
			return true
		_phase = "land"
		return false
	if _player == null:
		return true
	_frames += 1
	match _phase:
		"land":
			if _frames >= LAND_FRAMES:
				_check_landed()
				_move_start_z = _player.global_position.z
				Input.action_press("move_forward")
				_frames = 0
				_phase = "move"
		"move":
			if _frames >= MOVE_FRAMES:
				Input.action_release("move_forward")
				_check_moved()
				Input.action_press("jump")
				_jump_peak_y = 0.0
				_frames = 0
				_phase = "jump"
		"jump":
			_jump_peak_y = maxf(_jump_peak_y, _player.global_position.y)
			if _frames == 5:
				Input.action_release("jump")
			if _frames >= JUMP_FRAMES:
				_check_jumped()
				_finish()
				return true
	return false


func _check_landed() -> void:
	var y := _player.global_position.y
	if y < -1.0:
		_fail("player fell through ground (y=%.2f)" % y)
	elif _player.is_on_floor() and y > -0.5 and y < 0.3:
		_pass("player rested on floor after %d frames (y=%.2f)" % [LAND_FRAMES, y])
	else:
		_fail("player not resting on floor (on_floor=%s, y=%.2f)"
				% [_player.is_on_floor(), y])


func _check_moved() -> void:
	var dz := _player.global_position.z - _move_start_z
	if dz < -1.0:
		_pass("move_forward drove player forward %.2f m in %d frames"
				% [-dz, MOVE_FRAMES])
	else:
		_fail("move_forward did not move player (dz=%.2f)" % dz)


func _check_jumped() -> void:
	if _jump_peak_y > 0.4:
		_pass("jump reached peak y=%.2f" % _jump_peak_y)
	else:
		_fail("jump did not lift player (peak y=%.2f)" % _jump_peak_y)
	if _player.is_on_floor():
		_pass("player re-landed after jump (y=%.2f)" % _player.global_position.y)
	else:
		_fail("player still airborne %d frames after jump (y=%.2f)"
				% [JUMP_FRAMES, _player.global_position.y])


func _finish() -> void:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
