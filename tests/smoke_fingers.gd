extends SceneTree
## Smoke test for STO-CHARACTER-057 — five procedural fingers, two
## joints each, all the same length.
##   godot --headless -s res://tests/smoke_fingers.gd
##
## The hand used to be a solid block with four decorative knuckle
## ridges and no fingers at all. Laid out like a human hand — pointer,
## middle, ring, pinky in a row with the thumb apart and opposing —
## except every finger is the SAME LENGTH, so the hand reads as
## mechanical rather than as a copy of a human one.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _main: Node
var _arms


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		CharacterDB.selected_index = 0          # Grabber
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		# Spawn directly rather than hosting (STO-TOOLS-009).
		var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
		p.name = "1"
		_main.get_node("Players").add_child(p)
		return false
	if _ticks < 5:
		return false

	var player := _main.get_node_or_null("Players/1") as CharacterBody3D
	_arms = player.get_node_or_null("MechanicalArms") if player != null else null
	_check(_arms != null, "the Grabber has arms")
	if _arms == null:
		return _finish()

	# --- both hands have fingers ------------------------------------
	for arm in 2:
		var f: Node3D = _arms.call("fingers_root", arm)
		_check(f != null, "arm %d has a Fingers node" % arm)
		if f == null:
			return _finish()
		_check(f.get_child_count() == 5,
				"arm %d has exactly 5 fingers (%d)" % [arm, f.get_child_count()])

	# --- named like a human hand ------------------------------------
	for nm in ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]:
		_check(_arms.call("finger", 0, nm) != null,
				"there is a %s" % nm.to_lower())

	# --- two joints each, so three segments -------------------------
	var pointer: Node3D = _arms.call("finger", 0, "Pointer")
	var seg_lengths: Array = []
	var node: Node3D = pointer
	var segs := 0
	while true:
		var j := node.get_node_or_null("J%d" % segs) as Node3D
		if j == null:
			break
		var seg := j.get_node_or_null("Seg") as MeshInstance3D
		_check(seg != null, "segment %d has a mesh" % segs)
		if seg != null:
			seg_lengths.append((seg.mesh as BoxMesh).size.z)
		segs += 1
		node = j.get_node_or_null("End") as Node3D
		if node == null:
			break
	_check(segs == 3,
			"a finger is 3 segments, i.e. 2 bending joints (%d)" % segs)

	# --- ALL THE SAME LENGTH ----------------------------------------
	var lengths: Array = []
	for nm2 in ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]:
		lengths.append(_finger_length(_arms.call("finger", 0, nm2)))
	var shortest: float = lengths.min()
	var longest: float = lengths.max()
	_check(longest - shortest < 0.001,
			"every finger is the same length (%.3f to %.3f)"
			% [shortest, longest])
	_check(shortest > 0.0, "and they have a length at all (%.3f)" % shortest)

	# --- the thumb opposes the others -------------------------------
	var thumb: Node3D = _arms.call("finger", 0, "Thumb")
	var index: Node3D = _arms.call("finger", 0, "Pointer")
	_check(absf(thumb.rotation.z) > 0.5,
			"the thumb is turned to oppose the others (%.2f rad)"
			% thumb.rotation.z)
	_check(thumb.position.z < index.position.z,
			"the thumb sits back along the palm (z %.3f vs %.3f)"
			% [thumb.position.z, index.position.z])

	# --- curling actually moves things ------------------------------
	# NB: the hand no longer RESTS at curl 0 — since
	# STO-CHARACTER-059/060 it settles at REST_CURL, slightly relaxed,
	# and is driven every tick. So this checks what curl 0 means
	# (a straight finger) rather than comparing against whatever shape
	# the hand happened to be holding.
	_arms.call("set_hand_curl", 0, 0.0)
	var tip_zero := _tip_position(pointer)
	var straight_len := _finger_length(pointer)
	_check(absf(tip_zero.z - straight_len) < 0.001 and absf(tip_zero.y) < 0.001,
			"curl 0 is a straight finger (tip at z %.3f of %.3f)"
			% [tip_zero.z, straight_len])

	_arms.call("set_hand_curl", 0, 1.0)
	var tip_closed := _tip_position(pointer)
	var moved := tip_zero.distance_to(tip_closed)
	_check(moved > 0.05,
			"curling to 1 actually moves the fingertip (%.3f m)" % moved)
	# A curled finger reaches LESS far forward than a straight one —
	# it is folding in, not stretching out.
	_check(tip_closed.z < tip_zero.z,
			"a curled finger reaches less far forward (%.3f -> %.3f)"
			% [tip_zero.z, tip_closed.z])

	# Both hands are drivable, not just the first.
	_arms.call("set_hand_curl", 1, 1.0)
	var other: Node3D = _arms.call("finger", 1, "Middle")
	_check(other != null and _tip_position(other) != Vector3.ZERO,
			"the other hand curls too")

	_arms.call("set_hand_curl", 0, 0.0)
	_arms.call("set_hand_curl", 1, 0.0)
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


## Total length of a finger: the sum of its segment lengths.
func _finger_length(finger: Node3D) -> float:
	if finger == null:
		return 0.0
	var total := 0.0
	var node: Node3D = finger
	var i := 0
	while true:
		var j := node.get_node_or_null("J%d" % i) as Node3D
		if j == null:
			break
		var seg := j.get_node_or_null("Seg") as MeshInstance3D
		if seg != null:
			total += (seg.mesh as BoxMesh).size.z
		i += 1
		node = j.get_node_or_null("End") as Node3D
		if node == null:
			break
	return total


## Where the fingertip ends up, in the finger's own space.
func _tip_position(finger: Node3D) -> Vector3:
	if finger == null:
		return Vector3.ZERO
	var node: Node3D = finger
	var i := 0
	var last := Transform3D()
	while true:
		var j := node.get_node_or_null("J%d" % i) as Node3D
		if j == null:
			break
		last = last * j.transform
		var end := j.get_node_or_null("End") as Node3D
		if end == null:
			break
		last = last * end.transform
		node = end
		i += 1
	return last.origin


func _finish() -> bool:
	print("RESULT: FAIL (%d)" % _failures)
	quit(1)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
