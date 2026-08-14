extends SceneTree
## Smoke test for STO-CHARACTER-059 (fingers wrap around what you grab)
## and STO-CHARACTER-060 (punch mode clenches the fist).
##   godot --headless -s res://tests/smoke_finger_grip.gd
##
## One number decides the whole hand shape; where it comes from says
## what the hand is doing. This checks each source produces a
## different, correct shape — and, for wrapping, that a BIGGER object
## leaves the fingers LESS curled, which is the part that would
## otherwise be eyeballed.

const CharacterDB := preload("res://scripts/characters.gd")
const SETTLE := 90

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _arms
var _small: RigidBody3D
var _big: RigidBody3D
var _rest_curl := 0.0
var _small_curl := 0.0
var _big_curl := 0.0


func _make_box(nm: String, half: float, at: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = nm
	# NOT frozen: the arm has to be able to carry it to the hand, or
	# the fingers never reach it and close on nothing. Freezing these
	# was the flaw in the first version of this test — the boxes sat
	# metres away and every finger curled fully into empty air.
	rb.gravity_scale = 0.0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half, half, half) * 2.0
	cs.shape = box
	rb.add_child(cs)
	_main.add_child(rb)
	rb.global_position = at
	return rb


func _curl() -> float:
	return float(_arms.call("hand_curl", 0))


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_player = p
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_arms = _player.get_node_or_null("MechanicalArms")
			_check(_arms != null, "the Grabber has arms")
			if _arms == null:
				return _finish()
			_small = _make_box("SmallThing", 0.10, Vector3(1.0, 1.0, 40.0))
			_big = _make_box("BigThing", 0.55, Vector3(3.0, 1.0, 40.0))
			_next("rest")
		"rest":
			if _ticks < SETTLE:
				return false
			_rest_curl = _curl()
			# Holding nothing: relaxed, neither flat nor clenched.
			_check(_rest_curl > 0.01 and _rest_curl < 0.5,
					"an empty hand rests relaxed, not flat or clenched (%.2f)"
					% _rest_curl)
			_next("small")
		"small":
			if _ticks == 1:
				_arms.call("grab_body", 0, _small, _small.global_position)
				return false
			if _ticks < SETTLE:
				return false
			_small_curl = _curl()
			_check(_small_curl > _rest_curl,
					"grabbing closes the fingers (%.2f -> %.2f)"
					% [_rest_curl, _small_curl])
			_next("big")
		"big":
			if _ticks == 1:
				_arms.call("release", 0)
				_arms.call("grab_body", 0, _big, _big.global_position)
				return false
			if _ticks < SETTLE:
				return false
			_big_curl = _curl()
			# THE measurement that matters for 059.
			_check(_big_curl < _small_curl,
					"a BIGGER object leaves the fingers LESS curled (%.2f big vs %.2f small)"
					% [_big_curl, _small_curl])
			_check(_big_curl > 0.0,
					"but they still close a little on it (%.2f)" % _big_curl)
			_next("letgo")
		"letgo":
			if _ticks == 1:
				_arms.call("release", 0)
				return false
			if _ticks < SETTLE:
				return false
			_check(absf(_curl() - _rest_curl) < 0.02,
					"letting go opens them again (%.2f back to %.2f)"
					% [_curl(), _rest_curl])
			_next("fist")
		"fist":
			# STO-CHARACTER-060: punch mode clenches.
			if _ticks == 1:
				_arms.call("set_punch_mode", true)
				return false
			if _ticks == 3:
				# Partway through, so it is a MOTION and not a snap.
				var mid := _curl()
				_check(mid > _rest_curl and mid < 1.0,
						"the fist closes smoothly rather than snapping (%.2f)" % mid)
				return false
			if _ticks < SETTLE:
				return false
			_check(_curl() > 0.95,
					"punch mode clenches the fist (%.2f)" % _curl())
			_check(_curl() >= _small_curl,
					"a fist is at least as closed as a grip (%.2f vs %.2f)"
					% [_curl(), _small_curl])
			_next("open")
		"open":
			if _ticks == 1:
				_arms.call("set_punch_mode", false)
				return false
			if _ticks < SETTLE:
				return false
			_check(absf(_curl() - _rest_curl) < 0.02,
					"grab mode opens them again (%.2f)" % _curl())
			return _finish()
	return false


func _next(phase: String) -> void:
	_phase = phase
	_ticks = 0


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
