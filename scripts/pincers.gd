class_name PincerArms
extends Node3D
## Two pincer arms on the front of the giant spider (STO-ENEMIES-030).
##
## The spider already has four legs and they are busy holding it up.
## These are different limbs for a different job: reaching out, and —
## once the rest of EPI-ENEMIES-SPIDER-TAKES-YOU lands — taking hold of
## a player and carrying them off.
##
## They are also what makes the threat READABLE. You can see the
## pincers weaving and opening before anything happens to you, which is
## the difference between a monster that is frightening and a monster
## that is unfair.
##
## Built in code and seeded from the creature, like the rest of this
## spider, so no two have quite the same arms. Everything here is
## derived from the body it is attached to rather than typed in as
## measurements — a bigger spider gets proportionally bigger arms with
## nothing to re-tune, which is the same rule its legs and its
## clamber-reach already follow.

## Which side each arm sits on. Arms only, deliberately just two: a
## spider with four reaching limbs stops reading as a spider.
const ARMS: Array = [
	{"n": "ArmL", "x": -1.0},
	{"n": "ArmR", "x":  1.0},
]

## Two segments, then the pincer. An upper arm that swings out from the
## body and a forearm that does the reaching.
const SEGMENT_FRACTIONS: Array = [0.45, 0.55]

## Arm length as a multiple of how high the body rides. Tied to the
## creature's own size for the reason given above, and large enough
## that the arms comfortably out-reach the body — an arm that cannot
## reach past the thing it is bolted to is decoration.
const ARM_OF_HEIGHT := 0.85
## Thickness relative to length. Thicker than a leg: these are the
## heavy limbs, and they should look like they could lift you.
const ARM_TH_OF_LEN := 0.075

## Resting angles from straight-ahead, in radians. The upper arm rises
## and swings outward; the forearm drops back down and inward, so the
## pair makes a wide, high, ready-looking cradle rather than two sticks
## pointing at you.
const REST_YAW: Array = [0.55, -0.30]
const REST_PITCH: Array = [0.35, -0.55]

## How far the pincer halves swing when fully open, in radians.
const JAW_OPEN := 0.85
## Idle weave — slow, so it reads as menace rather than twitching.
const WEAVE_RATE := 0.9
const WEAVE_YAW := 0.16
const WEAVE_PITCH := 0.11
## The idle open/shut of the jaws while it hunts. Never fully shut, so
## you can always see they are jaws.
const IDLE_JAW_MIN := 0.15
const IDLE_JAW_MAX := 0.45

@export var variation_seed: int = 0

var _arms: Array = []
var _mat: StandardMaterial3D
var _arm_len := 1.0
var _arm_th := 0.1
var _phase := 0.0
var _jaw := 0.3          # 0 = shut, 1 = wide open
var _jaw_target := 0.3
var _reach_out := 0.0    # 0 = drawn back, 1 = stretched forward


## Build both arms onto a body of `body_size`, whose block rides at
## `body_height`. Call once, before use.
func build(body_size: Vector3, body_height: float,
		material: StandardMaterial3D) -> void:
	_mat = material
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed if variation_seed != 0 else 1
	# Seeded variation, same as the legs: some spiders are long-armed.
	var lanky: float = rng.randf_range(0.85, 1.2)
	var thick: float = rng.randf_range(0.85, 1.25)
	_arm_len = body_height * ARM_OF_HEIGHT * lanky
	_arm_th = _arm_len * ARM_TH_OF_LEN * thick

	for def in ARMS:
		_build_arm(def, body_size, body_height, rng)

	print("[PINCERS] 2 arms, length %.2f, thickness %.2f, reach %.2f (seed %d)"
			% [_arm_len, _arm_th, reach(), variation_seed])


func _build_arm(def: Dictionary, body_size: Vector3, body_height: float,
		rng: RandomNumberGenerator) -> void:
	var side: float = float(def["x"])
	var root := Node3D.new()
	root.name = String(def["n"])
	# On the FRONT face of the block (-Z is forward), out at the corner.
	root.position = Vector3(
			side * body_size.x * 0.5,
			body_height,
			-body_size.z * 0.5)
	add_child(root)

	var parent := root
	var names := ["Upper", "Fore"]
	var last_len := 0.0
	for i in SEGMENT_FRACTIONS.size():
		var seg_len: float = _arm_len * float(SEGMENT_FRACTIONS[i])
		var seg := _make_segment(String(names[i]), seg_len)
		# Segments extend along -Z (forward), so the arms reach ahead of
		# the creature rather than hanging down like the legs.
		if i > 0:
			seg.position = Vector3(0.0, 0.0, -last_len)
		# Yaw mirrors on the left arm; pitch does not.
		seg.rotation = Vector3(
				float(REST_PITCH[i]) + rng.randf_range(-0.08, 0.08),
				side * float(REST_YAW[i]) + rng.randf_range(-0.08, 0.08),
				0.0)
		parent.add_child(seg)
		parent = seg
		last_len = seg_len

	# The pincer: two halves hinged at the end of the forearm, opening
	# apart from each other.
	var head := Node3D.new()
	head.name = "Pincer"
	head.position = Vector3(0.0, 0.0, -last_len)
	parent.add_child(head)

	var jaw_len: float = _arm_len * 0.22
	var jaws: Array = []
	for j in 2:
		var jaw := _make_segment("Jaw%d" % j, jaw_len)
		# One half above, one below, so they close like a beak.
		jaw.rotation = Vector3((1.0 if j == 0 else -1.0) * JAW_OPEN * 0.3,
				0.0, 0.0)
		head.add_child(jaw)
		jaws.append(jaw)

	# The very tip, so anything can ask where the business end is
	# without knowing how an arm is put together.
	var tip := Node3D.new()
	tip.name = "Tip"
	tip.position = Vector3(0.0, 0.0, -jaw_len)
	head.add_child(tip)

	_arms.append({
		"root": root,
		"upper": root.get_node("Upper"),
		"fore": parent,
		"head": head,
		"jaws": jaws,
		"tip": tip,
		"side": side,
	})


## A box segment extending along -Z from its own origin.
func _make_segment(nm: String, length: float) -> Node3D:
	var joint := Node3D.new()
	joint.name = nm
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_arm_th, _arm_th, length)
	mesh.mesh = box
	mesh.material_override = _mat
	mesh.position = Vector3(0.0, 0.0, -length * 0.5)
	joint.add_child(mesh)
	return joint


func _process(delta: float) -> void:
	if _arms.is_empty():
		return
	_phase += delta * WEAVE_RATE

	# Idle jaw work: they never sit still and never shut completely.
	if _jaw_target < 0.0:
		var t: float = 0.5 + 0.5 * sin(_phase * 1.7)
		_jaw = lerpf(_jaw, lerpf(IDLE_JAW_MIN, IDLE_JAW_MAX, t), 6.0 * delta)
	else:
		_jaw = lerpf(_jaw, _jaw_target, 10.0 * delta)

	for i in _arms.size():
		var arm: Dictionary = _arms[i]
		var side: float = float(arm["side"])
		# The two arms weave OUT OF STEP with each other, which is what
		# stops a pair of limbs reading as one mirrored object.
		var off: float = 0.0 if i == 0 else PI * 0.6
		var sway: float = sin(_phase + off)
		var rise: float = sin(_phase * 1.3 + off)

		var upper: Node3D = arm["upper"]
		var fore: Node3D = arm["fore"]
		# Applied ON TOP of the built rest pose, never replacing it —
		# overwriting rotation here would straighten the arms out of
		# their shape the instant they moved, which is the mistake the
		# legs already document.
		upper.rotation.y = side * REST_YAW[0] + sway * WEAVE_YAW
		upper.rotation.x = REST_PITCH[0] + rise * WEAVE_PITCH
		# Reaching straightens the arm out and forward.
		fore.rotation.y = side * REST_YAW[1] * (1.0 - _reach_out * 0.8) \
				- sway * WEAVE_YAW * 0.5
		fore.rotation.x = REST_PITCH[1] * (1.0 - _reach_out * 0.8) \
				+ rise * WEAVE_PITCH * 0.5

		var jaws: Array = arm["jaws"]
		for j in jaws.size():
			var jaw := jaws[j] as Node3D
			jaw.rotation.x = (1.0 if j == 0 else -1.0) * JAW_OPEN * _jaw


# --- What the rest of the game asks of them --------------------------

## How far the pincers reach from the body, tip included.
func reach() -> float:
	return _arm_len + _arm_len * 0.22


## Where the business end of one arm is, in world space.
func tip_position(side_index: int) -> Vector3:
	if _arms.is_empty():
		return global_position
	var arm: Dictionary = _arms[clampi(side_index, 0, _arms.size() - 1)]
	return (arm["tip"] as Node3D).global_position


## Open (1.0) or shut (0.0) the pincers. Negative hands them back to
## their idle weave.
func set_jaw(open01: float) -> void:
	_jaw_target = open01 if open01 < 0.0 else clampf(open01, 0.0, 1.0)


## How far open the jaws actually are right now.
func jaw() -> float:
	return _jaw


## Stretch the arms forward (1.0) or draw them back (0.0).
func set_reach(out01: float) -> void:
	_reach_out = clampf(out01, 0.0, 1.0)


func arm_count() -> int:
	return _arms.size()
