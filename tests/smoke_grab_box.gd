extends SceneTree
## Headless smoke test for the Grabber holding a loose crate.
##
## This behaviour has been changed three times, each after the operator
## played the previous version:
##
##   STO-CHARACTER-003  reeled the crate INTO the shoulder
##   STO-CHARACTER-053  left it exactly where it was
##   STO-CHARACTER-055  picks it UP and holds it OUT IN FRONT
##
## The one constant: it must never be dragged into the player. That is
## what this test guards, and it is the assertion that has survived
## every rewrite. Detailed hold position lives in smoke_rmb_pickup.gd.
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
	# THE ONE CONSTANT (003 -> 053 -> 055): never dragged into you.
	#
	# Checked as TWO things, because the old single check was measuring
	# the wrong quantity. The crate is steered toward a point 2.4 m out
	# (HOLD_DIST) while the arm can only reach about 2.0, so where it
	# actually settles is an EQUILIBRIUM between the pull and the arm —
	# and that equilibrium moves when unrelated things change in the
	# world. Measured while adding the practice dummy (STO-ENEMIES-029),
	# a body 12 m away that never touches the crate:
	#
	#   no dummy .................................. 1.66 m
	#   dummy present, no collider ................ 1.66 m
	#   dummy solid, outside the players group .... 1.51 m
	#   dummy solid, inside the players group ..... 1.00 m
	#
	# Distance to the dummy made no difference at all, so this is
	# physics ordering, not a pull. The old threshold of 1.0 m sat
	# inside that band, which made an unrelated addition to the world
	# look like the return of a bug fixed three times.
	#
	# So: assert the thing that actually distinguishes the bug. When it
	# WAS broken the crate ended up AT the shoulder — about zero, and
	# behind the hands. Distance now only has to rule that out; the
	# real check is that the crate is still out FRONT.
	var fwd: Vector3 = -_player.global_transform.basis.z
	var to_box: Vector3 = _box.global_position - sp
	var in_front: float = to_box.normalized().dot(fwd.normalized())
	if after > 0.6:
		_pass("the held crate is kept away from the player (%.2f m from the shoulder)"
				% after)
	else:
		_fail("the crate was dragged into the player (%.2f -> %.2f m)"
				% [_dist_before, after])
	if in_front > 0.35:
		_pass("and held out in FRONT of the player (facing %.2f)" % in_front)
	else:
		_fail("the crate is not out in front any more (facing %.2f)" % in_front)
	# It is HELD, so it must not simply drop to the floor either.
	if _box.global_position.y > 0.6:
		_pass("it is held up rather than dropped (y %.2f)" % _box.global_position.y)
	else:
		_fail("the held crate fell to the floor (y %.2f)" % _box.global_position.y)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
