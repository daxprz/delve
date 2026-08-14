class_name QuadrupedBody
extends Node3D
## A four-legged body: a small block carried on four legs
## (STO-ENEMIES-018). Generated entirely in code, seeded so no two
## crawlers are quite alike.
##
## The gait is the interesting part. A humanoid plants two feet and
## swings its arms; a four-legged thing has to step in a pattern that
## keeps it upright. Diagonal pairs move together — front-left with
## back-right — so at every moment the other diagonal is still on the
## ground and it is never left unsupported. That is what makes it read
## as a crawler rather than a box sliding along.

## Which corner each leg sits at, and which diagonal PAIR it belongs
## to. Legs in the same pair swing together.
const LEGS: Array = [
	{"n": "LegFL", "x": -1.0, "z": -1.0, "pair": 0},
	{"n": "LegFR", "x":  1.0, "z": -1.0, "pair": 1},
	{"n": "LegBL", "x": -1.0, "z":  1.0, "pair": 1},
	{"n": "LegBR", "x":  1.0, "z":  1.0, "pair": 0},
]

## THREE segments (STO-ENEMIES-021), so a leg goes DOWN off the body,
## then UP to the knee, then DOWN to the floor — the real spider shape.
## Two segments could only go out-and-up then down, which reads as a
## bent stick rather than a leg hanging off a body.
const SEGMENTS := 3
## Each segment's share of the leg, body outward.
const SEGMENT_FRACTIONS: Array = [0.22, 0.36, 0.42]
## Cumulative angle of each segment from straight-down, in radians.
## Direction is (sin, -cos), so under 90 degrees points DOWN and over
## 90 points UP: 0.70 down, 2.20 up, 0.15 down again.
const SEGMENT_ANGLES: Array = [0.70, 2.20, 0.15]
## A giant lumbers: fewer, longer strides (STO-ENEMIES-021).
const STEP_RATE := 0.85      # was 2.6 — slow, deliberate
const STEP_LIFT := 0.20
const STEP_REACH := 0.55     # was 0.22 — big steps

# --- Spider silhouette (STO-ENEMIES-019) -----------------------------
## How far the first segment swings OUT to the side, and UP. A spider's
## legs go out and up from the body and only then bend down, so the
## knee sits ABOVE the body. Legs hanging straight down underneath
## read as a table, not a spider.
## Must exceed 90 degrees, or the knee stays BELOW the body and the
## thing looks like a table. At 2.05 rad (117) the first segment points
## out AND up, putting the knee above the block — the bent-over
## silhouette that reads as a spider.
const LEG_SPLAY := 2.05  # kept for reference; SEGMENT_ANGLES rules now
## The knee folds back further than the leg splayed, so the lower
## segment comes down past vertical and the foot reaches the floor
## well outside the body.
const KNEE_FOLD := 2.45
## A real spider's leg is NOT two equal bones: a shorter femur reaches
## out to the side, then a long tibia runs down to the ground. That
## split is what LIFTS the body (STO-ENEMIES-020). With equal segments
## the fold eats the extra length and longer legs just splay wider
## while the body stays at knee height.
const FEMUR_FRACTION := 0.34

@export var variation_seed: int = 0
@export var base_color: Color = Color(0.35, 0.55, 0.30)

var _body_size := Vector3(0.44, 0.30, 0.60)
var _leg_len := 0.46
var _leg_th := 0.09
var _phase := 0.0
var _legs: Array = []        # {root, upper, lower, pair, rest}
var _mat: StandardMaterial3D
var _speed := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed if variation_seed != 0 else 1
	# Seeded variation: chunky squat ones and lanky tall ones, from
	# the same code.
	var bulk := rng.randf_range(0.82, 1.25)
	var lanky := rng.randf_range(0.80, 1.30)
	# One block, low and wide, carried between BIG legs
	# (STO-ENEMIES-019). The legs, not the body, are what you see.
	_body_size = Vector3(0.40 * bulk, 0.24 * bulk, 0.52 * bulk)
	# TOWERING (STO-ENEMIES-020): long enough that its body rides
	# above head height and you walk underneath it.
	_leg_len = 7.00 * lanky
	_leg_th = 0.30 * bulk        # thick enough to carry something giant

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = base_color
	_mat.roughness = 0.7

	_build_body()
	for def in LEGS:
		_build_leg(def)
	print("[QUADRUPED] built %d legs, block body %.2fx%.2fx%.2f (seed %d)"
			% [_legs.size(), _body_size.x, _body_size.y, _body_size.z,
			variation_seed])


func _build_body() -> void:
	var block := MeshInstance3D.new()
	block.name = "Block"
	var box := BoxMesh.new()
	box.size = _body_size
	block.mesh = box
	block.material_override = _mat
	block.position = Vector3(0.0, _body_height(), 0.0)
	add_child(block)


## How high the block rides — DERIVED from the leg geometry, not
## picked (STO-ENEMIES-020).
##
## The femur goes out and UP by cos(splay); the tibia then comes down
## by cos(splay - fold). Whatever is left over is how high the body can
## sit with its feet still on the floor. Choosing a height instead
## leaves the feet floating above the ground or buried in it.
func _body_height() -> float:
	# Sum every segment's contribution to the foot's HEIGHT, then sit
	# exactly that high — otherwise the feet float above the floor or
	# sink through it. Derived, never picked.
	var drop := 0.0
	for i in SEGMENTS:
		drop += _leg_len * float(SEGMENT_FRACTIONS[i]) * -cos(float(SEGMENT_ANGLES[i]))
	return maxf(-drop, 0.2)


func _build_leg(def: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(def["n"])
	var side: float = float(def["x"])
	root.position = Vector3(
			side * _body_size.x * 0.5,
			_body_height(),
			float(def["z"]) * _body_size.z * 0.42)
	add_child(root)

	# Each joint's rotation is the CHANGE from the previous segment's
	# angle, because they are nested — a delta, not the absolute angle.
	var parent := root
	var names := ["Upper", "Lower", "Foot"]
	var prev_angle := 0.0
	var last: Node3D = null
	var last_len := 0.0
	for i in SEGMENTS:
		var seg_len: float = _leg_len * float(SEGMENT_FRACTIONS[i])
		var angle: float = float(SEGMENT_ANGLES[i])
		var joint := _make_segment(String(names[i]), seg_len)
		joint.rotation = Vector3(0.0, 0.0, side * (angle - prev_angle))
		if i > 0:
			joint.position = Vector3(0.0, -last_len, 0.0)
		parent.add_child(joint)
		parent = joint
		prev_angle = angle
		last = joint
		last_len = seg_len

	_legs.append({
		"root": root, "upper": root.get_node("Upper"), "lower": last,
		"pair": int(def["pair"]), "seg": last_len,
	})


func _make_segment(nm: String, length: float) -> Node3D:
	var joint := Node3D.new()
	joint.name = nm
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_leg_th, length, _leg_th)
	mesh.mesh = box
	mesh.material_override = _mat
	mesh.position = Vector3(0.0, -length * 0.5, 0.0)
	joint.add_child(mesh)
	return joint


## Called each tick with how fast the creature is actually moving, so
## the legs step in time with the ground rather than running on the
## spot.
func set_speed(speed: float) -> void:
	_speed = speed


func _process(delta: float) -> void:
	if _legs.is_empty():
		return
	_phase += delta * STEP_RATE * clampf(_speed / 3.0, 0.0, 2.0)
	for leg_v in _legs:
		var leg: Dictionary = leg_v
		# Diagonal pairs are half a stride apart, so one diagonal is
		# always down while the other swings.
		var t: float = _phase + (0.5 if int(leg["pair"]) == 1 else 0.0)
		var swing: float = sin(t * TAU)
		var lift: float = maxf(sin(t * TAU), 0.0)
		var upper: Node3D = leg["upper"]
		var lower: Node3D = leg["lower"]
		# Applied ON TOP of the splayed rest pose, not instead of it —
		# overwriting the rotation would straighten the leg out of its
		# spider shape the moment it started walking.
		upper.rotation.x = swing * STEP_REACH
		lower.rotation.x = -lift * STEP_LIFT * 4.0


## Where each foot is, in local space (for tests).
func foot_positions() -> Array:
	var out: Array = []
	for leg_v in _legs:
		var leg: Dictionary = leg_v
		var lower: Node3D = leg["lower"]
		out.append(to_local(lower.global_transform * Vector3(0.0, -float(leg["seg"]), 0.0)))
	return out


## Where each KNEE is, in local space (for tests).
func knee_positions() -> Array:
	var out: Array = []
	for leg_v in _legs:
		var leg: Dictionary = leg_v
		var lower: Node3D = leg["lower"]
		out.append(to_local(lower.global_position))
	return out


## How high the block rides, for tests.
func body_height() -> float:
	return _body_height()


func leg_count() -> int:
	return _legs.size()


func body_size() -> Vector3:
	return _body_size
