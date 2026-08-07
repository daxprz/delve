extends SceneTree
## Headless smoke test for STO-CHARACTER-002 solidity: even when a hand
## grabs a point FAR beyond the arm's reach, the arm must stay in one
## solid piece (segments keep their length) — it may not split into gaps.
## Also checks the grab reach is gradual (heavy), not an instant snap.
## Run with:  godot --headless -s res://tests/smoke_arm_solid.gd

const SETTLE := 30
const HOLD := 60

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _far := Vector3.ZERO
var _dist_1_frame := 0.0
var _worst_stretch := 1.0


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no arms")
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
				# Grab a point WAY out of reach (5 m from the shoulder).
				var sp: Vector3 = _arms.shoulder_point(0)
				_far = sp + Vector3(0.0, 0.0, -5.0)
				_arms.grab(0, _far)
				_frames = 0
				_phase = "reach1"
		"reach1":
			# One frame after grabbing: a heavy hand should NOT already be
			# at the target (that would be an instant snap).
			var hp: Vector3 = _arms.hand_point(0)
			_dist_1_frame = hp.distance_to(_far)
			_frames = 0
			_phase = "hold"
		"hold":
			_frames += 1
			var s: float = _arms.max_segment_stretch(0)
			_worst_stretch = maxf(_worst_stretch, s)
			if _frames >= HOLD:
				_check_solid()
				_check_heavy()
				return _done()
	return false


func _check_solid() -> void:
	# Segments must stay near their rest length (no pulling apart).
	if _worst_stretch < 1.15:
		_pass("arm stayed solid grabbing out of reach (max stretch x%.2f)"
				% _worst_stretch)
	else:
		_fail("arm pulled apart into gaps (max stretch x%.2f)" % _worst_stretch)


func _check_heavy() -> void:
	# Heavy reach: the hand should not have teleported onto the far point
	# in a single frame (a large arm can't cover 5 m instantly anyway,
	# but this guards against a hard snap).
	if _dist_1_frame > 1.0:
		_pass("grab reaches heavily, no instant snap (%.2f m off after 1 frame)"
				% _dist_1_frame)
	else:
		_fail("hand snapped instantly to the target (%.2f m off after 1 frame)"
				% _dist_1_frame)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
