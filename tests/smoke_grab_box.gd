extends SceneTree
## Headless smoke test for STO-CHARACTER-003 box-grab (bugfix): grabbing
## a movable RigidBody reels it toward the player's hand.
## Run with:  godot --headless -s res://tests/smoke_grab_box.gd

const SETTLE := 30
const HOLD := 120

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _box: RigidBody3D
var _dist_before := 0.0


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_box = _main.get_node_or_null("Playground/MovableBox") as RigidBody3D
	_main.host_game()
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null or _box == null:
		_fail("missing player or box")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no arms")
		return false
	# Put the box a couple of metres in front of the player.
	_box.global_position = _player.global_position + Vector3(0.0, 0.8, -2.5)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_phase = "settle"
		"settle":
			_frames += 1
			if _frames >= SETTLE:
				var sp: Vector3 = _arms.shoulder_point(0)
				_dist_before = sp.distance_to(_box.global_position)
				_arms.grab_body(0, _box, _box.global_position)
				if _arms.is_grabbed(0):
					_pass("grab_body(0, box) engaged")
				else:
					_fail("grab_body did not engage")
				_frames = 0
				_phase = "hold"
		"hold":
			_frames += 1
			if _frames >= HOLD:
				_check_reeled()
				return _done()
	return false


func _check_reeled() -> void:
	var sp: Vector3 = _arms.shoulder_point(0)
	var after := sp.distance_to(_box.global_position)
	if after < _dist_before - 0.3:
		_pass("grabbing the box reeled it toward the hand (%.2f -> %.2f m)"
				% [_dist_before, after])
	else:
		_fail("box was not reeled in (%.2f -> %.2f m)" % [_dist_before, after])


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
