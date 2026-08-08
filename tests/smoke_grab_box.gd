extends SceneTree
## Headless smoke test for the Grabber holding a loose crate.
##
## STO-CHARACTER-003 originally REELED a grabbed crate toward the hand.
## STO-CHARACTER-053 reversed that on the operator's instruction: the
## crate must now stay exactly where it is, with the arm stretching out
## to reach it, so a throw launches from a standing start and lands in
## the same place every time.
##
## This test was inverted deliberately — the requirement changed, the
## code did not merely drift.
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
var _box_start := Vector3.ZERO


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_box = _main.get_node_or_null("Playground/MovableBox") as RigidBody3D
	# No hosting: nothing here needs a network, and hosting makes this
	# unrunnable while the operator has the game open on port 7777.
	var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	p.name = "1"
	_main.get_node("Players").add_child(p)
	_player = p
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
				_box_start = _box.global_position
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
	# THE POINT (STO-CHARACTER-053): it must NOT come to you.
	if after > _dist_before - 0.3:
		_pass("the grabbed crate stays put (%.2f -> %.2f m from the shoulder)"
				% [_dist_before, after])
	else:
		_fail("the crate was dragged toward the player (%.2f -> %.2f m)"
				% [_dist_before, after])
	# And it must not have wandered off on its own either.
	var moved := _box_start.distance_to(_box.global_position)
	if moved < 0.5:
		_pass("it stayed where it was grabbed (moved %.2f m)" % moved)
	else:
		_fail("it drifted %.2f m from where it was grabbed" % moved)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
