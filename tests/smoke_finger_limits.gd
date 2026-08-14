extends SceneTree
## Smoke test for STO-CHARACTER-058 — fingers bend like real fingers.
##   godot --headless -s res://tests/smoke_finger_limits.gd
##
## The operator asked for this up front: "make sure they act like real
## fingers so they can't bend too far back or clip into each other."
## Both were real at the time it was asked — measured, not supposed:
##   * at full curl the fingertip sat INSIDE the palm block (y -0.101
##     against a palm spanning +/-0.20)
##   * the four fingers OVERLAPPED by 2.2 mm (spacing 0.0728,
##     thickness 0.075)
##
## This measures positions in world space, so it fails if the geometry
## drifts even if the constants still look sensible.

const CharacterDB := preload("res://scripts/characters.gd")
## The palm block is FIST_TH on a side, centred on the hand origin.
const PALM_HALF := 0.20
const PALM_LEN := 0.34

var _failures := 0
var _ticks := 0
var _main: Node
var _arms
var _hand: Node3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		CharacterDB.selected_index = 0
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
		p.name = "1"
		_main.get_node("Players").add_child(p)
		return false
	if _ticks < 5:
		return false

	var player := _main.get_node_or_null("Players/1") as CharacterBody3D
	_arms = player.get_node_or_null("MechanicalArms") if player != null else null
	if _arms == null:
		_check(false, "the Grabber has arms")
		return _finish()
	_hand = (_arms.get_node_or_null("ArmLeft/Hand")) as Node3D
	_check(_hand != null, "there is a hand")
	if _hand == null:
		return _finish()

	# --- 1. cannot bend backwards past straight ---------------------
	_arms.call("set_hand_curl", 0, 0.0)
	var straight := _joint_angles("Pointer")
	_arms.call("set_hand_curl", 0, -5.0)      # shove it the wrong way
	var backwards := _joint_angles("Pointer")
	_check(backwards == straight,
			"a negative curl cannot bend a finger backwards (%s vs %s)"
			% [str(backwards), str(straight)])
	for a in straight:
		_check(a <= 0.0001,
				"a resting finger is straight, not pre-bent (%.3f)" % a)

	# --- 2. cannot curl past a closed fist --------------------------
	_arms.call("set_hand_curl", 0, 1.0)
	var full := _joint_angles("Pointer")
	_arms.call("set_hand_curl", 0, 9.0)       # shove it far too far
	var over := _joint_angles("Pointer")
	_check(over == full,
			"curling past 1 changes nothing — it is already closed")

	# --- 3. no finger folds through the palm ------------------------
	# THE measurement that caught the original geometry.
	for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
		_arms.call("set_hand_curl", 0, t)
		var worst := ""
		for nm in ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]:
			if _finger_in_palm(nm):
				worst = nm
				break
		_check(worst == "",
				"at curl %.2f no finger is inside the palm%s"
				% [t, "" if worst == "" else " (%s is)" % worst])

	# --- 4. fingers do not pass through each other ------------------
	for t2 in [0.0, 0.5, 1.0]:
		_arms.call("set_hand_curl", 0, t2)
		var order := ["Pointer", "Middle", "Ring", "Pinky"]
		var closest := 999.0
		var pair := ""
		for i in order.size() - 1:
			var d := _closest_gap(String(order[i]), String(order[i + 1]))
			if d < closest:
				closest = d
				pair = "%s/%s" % [order[i], order[i + 1]]
		_check(closest > 0.0,
				"at curl %.2f neighbouring fingers do not overlap (%s gap %.4f m)"
				% [t2, pair, closest])

	# --- 5. the thumb keeps out of the fingers ----------------------
	for t3 in [0.0, 1.0]:
		_arms.call("set_hand_curl", 0, t3)
		var g := _closest_gap("Thumb", "Pinky")
		var g2 := _closest_gap("Thumb", "Pointer")
		_check(minf(g, g2) > 0.0,
				"at curl %.2f the thumb does not pass through a finger (%.4f m)"
				% [t3, minf(g, g2)])

	_arms.call("set_hand_curl", 0, 0.0)
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


## The bend angle at each joint of a finger.
func _joint_angles(nm: String) -> Array:
	var out: Array = []
	var f: Node3D = _arms.call("finger", 0, nm)
	if f == null:
		return out
	var node: Node3D = f
	var i := 0
	while true:
		var j := node.get_node_or_null("J%d" % i) as Node3D
		if j == null:
			break
		out.append(snappedf(j.rotation.x, 0.0001))
		node = j.get_node_or_null("End") as Node3D
		if node == null:
			break
		i += 1
	return out


## Every segment centre of a finger, in HAND space.
func _seg_points(nm: String) -> Array:
	var pts: Array = []
	var f: Node3D = _arms.call("finger", 0, nm)
	if f == null:
		return pts
	var node: Node3D = f
	var i := 0
	while true:
		var j := node.get_node_or_null("J%d" % i) as Node3D
		if j == null:
			break
		var seg := j.get_node_or_null("Seg") as Node3D
		if seg != null:
			pts.append(_hand.to_local(seg.global_position))
		node = j.get_node_or_null("End") as Node3D
		if node == null:
			break
		i += 1
	return pts


## Is any MOVING part of this finger inside the solid palm block?
##
## The base knuckle is skipped on purpose: it is the attachment, and
## on a real hand a thumb's base sits inside the palm too. What must
## never happen is a finger FOLDING through the hand as it curls, and
## that is what the segments past the base show.
func _finger_in_palm(nm: String) -> bool:
	var pts := _seg_points(nm)
	for i in range(1, pts.size()):
		var v: Vector3 = pts[i]
		if absf(v.x) < PALM_HALF and absf(v.y) < PALM_HALF \
				and v.z > 0.0 and v.z < PALM_LEN:
			return true
	return false


## Closest surface gap between two fingers (negative = overlapping).
func _closest_gap(a: String, b: String) -> float:
	var pa := _seg_points(a)
	var pb := _seg_points(b)
	var best := 999.0
	var th: float = float(_arms.get("FINGER_TH")) * float(_arms.get("arm_scale"))
	for x in pa:
		for y in pb:
			var d: float = (x as Vector3).distance_to(y as Vector3) - th
			if d < best:
				best = d
	return best


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
