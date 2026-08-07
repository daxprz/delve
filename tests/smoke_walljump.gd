extends SceneTree
## Headless smoke test for STO-CHARACTER-018 (Runner wall-jump + sprint).
## Run with:  godot --headless -s res://tests/smoke_walljump.gd
##
## Drives the Runner into the big wall in the air and jumps: it should
## launch AWAY from the wall and upward (a wall-jump), not fall straight.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _launch := Vector3.ZERO


func _setup() -> bool:
	CharacterDB.selected_index = 1  # Runner
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no runner")
		return false
	# Place the Runner in the air just in front of the big wall's front face
	# (wall is at z=-11, thickness 0.8 -> front face ~z=-10.6), facing it.
	_player.global_position = Vector3(0.0, 3.0, -10.0)
	_player.rotation = Vector3.ZERO   # faces -Z, toward the wall
	Input.action_press("move_forward") # push into the wall
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "approach"
		"approach":
			_frames += 1
			# Once we're touching the wall (in the air), jump (keep pushing
			# into the wall so is_on_wall stays true when the jump fires).
			if _player.is_on_wall() and not _player.is_on_floor():
				Input.action_press("jump")
				_phase = "jump"
				_frames = 0
			elif _frames > 90:
				_fail("Runner never reached the wall")
				return _done()
		"jump":
			_frames += 1
			if _frames == 1:
				Input.action_release("jump")
			if _frames >= 3:
				# Capture the launch velocity a couple frames after jumping.
				_launch = _player.velocity
				_check()
				return _done()
	return false


func _check() -> void:
	# Wall normal points +Z (away from the wall toward the player), so a
	# wall-jump should send us +Z (away) and upward.
	if _launch.z > 1.0:
		_pass("wall-jump launches the Runner away from the wall (vz=%.1f)" % _launch.z)
	else:
		_fail("did not launch away from the wall (vz=%.1f)" % _launch.z)
	if _launch.y > 1.0:
		_pass("wall-jump launches the Runner upward (vy=%.1f)" % _launch.y)
	else:
		_fail("wall-jump gave no upward launch (vy=%.1f)" % _launch.y)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
