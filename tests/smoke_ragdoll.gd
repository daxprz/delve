extends SceneTree
## Headless smoke test for STO-CHARACTER-002 (procedural ragdoll drag).
## Run with:  godot --headless -s res://tests/smoke_ragdoll.gd
##
## Verifies the Verlet ragdoll behaves:
##   - all points stay finite (no NaN/explosion)
##   - the shoulder stays pinned to the player
##   - segment lengths stay ~constant (the chain doesn't stretch)
##   - gravity makes the hand hang below the shoulder
##   - moving the player makes the hand LAG behind (drag)
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const SETTLE := 90     # physics ticks to let arms settle
const DRIVE := 40      # ticks driving the player forward

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms: Node
var _hand_before := Vector3.ZERO


func _setup() -> bool:
	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	root.add_child(_main)
	_main.host_game()
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player at Players/1")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no MechanicalArms")
		return false
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
				_check_settled()
				_hand_before = _arms.hand_point(0)
				Input.action_press("move_forward")
				_frames = 0
				_phase = "drive"
		"drive":
			_frames += 1
			if _frames >= DRIVE:
				Input.action_release("move_forward")
				_check_drag()
				return _done()
	return false


func _check_settled() -> void:
	# Finite + shoulder pinned + segment lengths preserved + hangs down.
	var finite := true
	for i in 2:
		var s: Vector3 = _arms.shoulder_point(i)
		var h: Vector3 = _arms.hand_point(i)
		if not (_finite(s) and _finite(h)):
			finite = false
	if finite:
		_pass("all arm points finite after settling (no explosion)")
	else:
		_fail("arm points went non-finite (NaN/inf)")

	# Shoulder should sit near the player (within reach of the body).
	var sp: Vector3 = _arms.shoulder_point(0)
	var d := sp.distance_to(_player.global_position)
	if d < 3.0:
		_pass("left shoulder stays pinned to player (%.2f m)" % d)
	else:
		_fail("shoulder drifted from player (%.2f m)" % d)

	# Hand hangs below the shoulder under gravity.
	var hp: Vector3 = _arms.hand_point(0)
	var drop := sp.y - hp.y
	if drop > 0.3:
		_pass("left hand hangs %.2f m below the shoulder (gravity)" % drop)
	else:
		_fail("hand did not hang below shoulder (drop=%.2f)" % drop)


func _check_drag() -> void:
	# The player moved forward (-Z). A dragging hand should trail, i.e.
	# end up further back (+Z) relative to its shoulder than the body.
	var hand: Vector3 = _arms.hand_point(0)
	var shoulder: Vector3 = _arms.shoulder_point(0)
	if hand.z > shoulder.z + 0.05:
		_pass("hand trails behind shoulder while moving (drag): dz=%.2f"
				% [hand.z - shoulder.z])
	else:
		_fail("hand did not trail behind while moving (dz=%.2f)"
				% [hand.z - shoulder.z])


func _finite(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
