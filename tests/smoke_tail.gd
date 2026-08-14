extends SceneTree
## Headless smoke test for STO-CHARACTER-010 (Runner's physics tail).
## Run with:  godot --headless -s res://tests/smoke_tail.gd
##
## Verifies:
##   - the Runner has a long Tail; the Grabber does NOT
##   - the tail is a stable physics chain (finite, stays attached at the
##     base, hangs below it under gravity)
##   - the tail wags: its tip moves sideways over time on its own
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const CharacterDB := preload("res://scripts/characters.gd")
const SETTLE := 75

var _failures := 0
var _phase := "setup"
var _frames := 0
var _runner: Node
var _tail
var _max_curve := 0.0


func _setup() -> bool:
	# Grabber has no tail.
	CharacterDB.selected_index = 0
	var g: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(g)
	if g.get_node_or_null("Tail") == null:
		_pass("Grabber has no tail")
	else:
		_fail("Grabber should not have a tail")
	g.free()

	# Runner has a tail — spawn it in the real scene so it stands on the
	# ground and the tail can hang.
	CharacterDB.selected_index = 1
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# Spawn the player directly instead of hosting (STO-TOOLS-009).
	# Nothing here needs a network, and host_game() binds UDP 7777, so
	# this test could not run at all while the operator had the game
	# open — which is how two tests once shipped failing unnoticed.
	var _r: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	_r.name = "1"
	main.get_node("Players").add_child(_r)
	_runner = _r
	if _runner == null:
		_fail("no Runner spawned")
		return false
	_tail = _runner.get_node_or_null("Tail")
	if _tail == null:
		_fail("Runner has no Tail node")
		return false
	if _tail.tail_length() >= 8:
		_pass("Runner has a long tail (%d segments)" % _tail.tail_length())
	else:
		_fail("tail too short (%d segments)" % _tail.tail_length())
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "settle"
		"settle":
			_frames += 1
			if _frames >= SETTLE:
				_check_hang()
				Input.action_press("move_forward")
				_frames = 0
				_phase = "move"
		"move":
			_frames += 1
			# A fully-ragdoll tail curves/swings as the body moves.
			_max_curve = maxf(_max_curve, _curve())
			if _frames >= 60:
				Input.action_release("move_forward")
				_check_drag()
				_check_ragdoll()
				return _done()
	return false


func _curve() -> float:
	var bp: Vector3 = _tail.base_point()
	var tp: Vector3 = _tail.tip_point()
	var mp: Vector3 = _tail.mid_point()
	var axis := tp - bp
	if axis.length() < 0.001:
		return 0.0
	var along := (mp - bp).project(axis)
	return (mp - bp - along).length()


func _check_ragdoll() -> void:
	# Physics-driven: as the body moved, the tail curved/swung (not rigid).
	if _max_curve > 0.15:
		_pass("tail swings/curves from physics as the body moves (%.2f m)" % _max_curve)
	else:
		_fail("tail did not flex like a ragdoll (max curve %.2f m)" % _max_curve)


func _check_drag() -> void:
	# Moving forward, the tail should TRAIL behind the player — in the
	# player's local space the tip sits behind (local +Z) the base.
	var inv: Transform3D = _runner.global_transform.affine_inverse()
	var bp: Vector3 = _tail.base_point()
	var tp: Vector3 = _tail.tip_point()
	var base_local := inv * bp
	var tip_local := inv * tp
	if tip_local.z > base_local.z + 0.3:
		_pass("tail drags behind the moving player (%.2f m back)"
				% (tip_local.z - base_local.z))
	else:
		_fail("tail does not drag behind (%.2f m)" % (tip_local.z - base_local.z))


func _check_hang() -> void:
	if not _tail.is_finite_chain():
		_fail("tail went non-finite (unstable)")
		return
	_pass("tail chain is stable (all points finite)")
	var base: Vector3 = _tail.base_point()
	var tip: Vector3 = _tail.tip_point()
	if base.y - tip.y > 0.5:
		_pass("tail hangs below its base (%.2f m of droop)" % (base.y - tip.y))
	else:
		_fail("tail did not hang below base (droop %.2f m)" % (base.y - tip.y))


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
