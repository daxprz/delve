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

const PincerScript := preload("res://scripts/pincers.gd")

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
## Each segment's share of the leg, body outward — the STARTING point
## for a spider's proportions (STO-ENEMIES-022). The last segment is
## far the longest: two short joints close to the body, then one long
## reach down to the floor.
##
## Jittered per spider from its seed, so no two have the same build —
## some lankier, some more gathered up.
## Three. A fourth foot segment was added and then removed at the
## operator's request (STO-ENEMIES-025) — the leg ends at the long
## reach.
const SEGMENT_FRACTIONS: Array = [0.13, 0.19, 0.68]
## Cumulative angle of each segment from straight-down, in radians.
## Direction is (sin, -cos), so under 90 degrees points DOWN and over
## 90 points UP: 0.70 down, 2.20 up, 0.15 down again.
## Shaped like the END OF AN X (STO-ENEMIES-023): the middle segment
## rises STEEPLY rather than reaching outward, so the knee is a sharp
## high peak and the leg makes a narrow inverted V. At 2.20 the middle
## segment went out almost as much as up, which rounds the peak off
## into a shrug.
##   0.55 down-and-out, 2.65 steeply UP, 0.10 straight back DOWN
const SEGMENT_ANGLES: Array = [0.55, 2.65, 0.10]
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

# --- Floppy limbs (STO-ENEMIES-037) ----------------------------------
# Long loose limbs slung off a body that drags them around, rather than
# a frame with everything bolted where it belongs.
#
# Driven by what the creature is ACTUALLY doing — start, stop or turn
# and the limbs lag, then overshoot and settle. Not a looping wobble:
# a spider standing still has still legs, which is the same principle
# the gait already follows and the reason this reads as weight rather
# than as an effect pasted on top.
## Radians of lag per m/s that the creature's velocity has run ahead of
## its own smoothed velocity — i.e. per unit of starting, stopping or
## turning. NOT per unit of acceleration: see _update_flop for why
## double-differencing position was abandoned.
const FLOP_DRIVE := 0.075
## How fast the smoothed velocity catches up. Lower = limbs notice
## slower changes; higher = only sharp lurches register.
const FLOP_SMOOTH := 6.0
## How hard limbs are pulled back into line.
const FLOP_STIFF := 7.0
## Damping. Deliberately LOW — this is what makes them overshoot and
## swing past instead of easing neatly home. Rubbery was asked for.
const FLOP_DAMP := 2.4
## Ceiling on the lag, so a violent shove cannot fold the legs inside
## out.
const FLOP_MAX := 0.60
## How much each driven joint swings. The far joint swings more than
## the near one, which is what a long loose limb does — equal shares
## would read as the whole leg rotating rigidly about its socket.
const FLOP_NEAR := 0.40
const FLOP_FAR := 1.00
# --- Limbs lagging their own gait (STO-ENEMIES-039) ------------------
# Each joint is a damped spring chasing the angle the gait asks for
# rather than snapping to it. Deliberately UNDERDAMPED, so a limb
# overshoots when its swing reverses instead of easing neatly in.
#
# The far joint is much softer than the near one. That difference is
# the whole look: the end of a long limb whips along behind the part
# near the socket, which is what "loose" actually means. Equal
# stiffness would make the leg lag as one rigid piece.
const JOINT_STIFF_NEAR := 42.0
const JOINT_DAMP_NEAR := 6.5
const JOINT_STIFF_FAR := 21.0
const JOINT_DAMP_FAR := 3.4
## Ceiling on how far behind a joint may fall, so a spider spun hard
## cannot wind a limb round on itself.
const JOINT_LAG_MAX := 1.4

## How far a limb hangs when a hit knocks the life out of it.
const LIMP_DROOP := 0.85
## How long it dangles before gathering itself back up.
const LIMP_TIME := 0.7

@export var variation_seed: int = 0
@export var base_color: Color = Color(0.35, 0.55, 0.30)

var _body_size := Vector3(0.44, 0.30, 0.60)
var _leg_len := 0.46
var _leg_th := 0.09
var _phase := 0.0
var _legs: Array = []        # {root, upper, lower, pair, rest}
## This individual's leg proportions and angles, seeded in _ready.
var _fracs: Array = SEGMENT_FRACTIONS.duplicate()
var _angles: Array = SEGMENT_ANGLES.duplicate()
var _mat: StandardMaterial3D
var _pincers: Node3D          # the reaching arms (STO-ENEMIES-030)
# Floppiness (STO-ENEMIES-037): a damped spring chasing the lag that
# the creature's own acceleration calls for.
var _flop := Vector2.ZERO     # current lag, local (x = sideways, y = fore/aft)
var _flop_v := Vector2.ZERO   # its velocity, which is what overshoots
var _prev_pos := Vector3.INF
var _vel_smooth := Vector3.ZERO
var _limp := 0.0              # seconds of dangle left
var _speed := 0.0
## Stride length multiplier, tuned by the creature's own mind while it
## walks (STO-ENEMIES-043). Starts at 1.0 — the gait it has always had,
## which is the operator's "it already existed before the player was
## there".
var _gait_scale := 1.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed if variation_seed != 0 else 1
	# Seeded variation: chunky squat ones and lanky tall ones, from
	# the same code.
	var bulk := rng.randf_range(0.82, 1.25)
	var lanky := rng.randf_range(0.80, 1.30)
	# SLENDER (STO-ENEMIES-022): a small body slung under long thin
	# legs. The legs, not the body, are what you see.
	_body_size = Vector3(0.30 * bulk, 0.17 * bulk, 0.40 * bulk)

	# Procedural proportions: jitter each segment's share, then
	# renormalise so the leg is still exactly _leg_len long. Without
	# the renormalise, a spider that rolled three high numbers would
	# simply have longer legs rather than DIFFERENT ones.
	var raw: Array = []
	var total := 0.0
	for i in SEGMENT_FRACTIONS.size():
		var f: float = float(SEGMENT_FRACTIONS[i]) * rng.randf_range(0.82, 1.18)
		raw.append(f)
		total += f
	_fracs = []
	for f2 in raw:
		_fracs.append(float(f2) / total)
	# The angles vary a little too, so some stand tall and some crouch.
	_angles = []
	for a in SEGMENT_ANGLES:
		_angles.append(float(a) + rng.randf_range(-0.10, 0.10))
	# TOWERING (STO-ENEMIES-020): long enough that its body rides
	# above head height and you walk underneath it.
	# Shorter overall than before, because the long third segment now
	# does nearly all the lifting: at 7.4 the body ended up 5.7 m up,
	# which is a building rather than a spider.
	_leg_len = 4.30 * lanky
	_leg_th = 0.155 * bulk       # slender

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = base_color
	_mat.roughness = 0.7

	_build_body()
	for def in LEGS:
		_build_leg(def)
	# Pincer arms (STO-ENEMIES-030). Their own node rather than more
	# code in here: the legs are about carrying the creature and the
	# arms are about reaching for you, and every story left in this epic
	# touches the arms and none of them touch the gait.
	_pincers = PincerScript.new()
	_pincers.name = "Pincers"
	_pincers.set("variation_seed", variation_seed)
	add_child(_pincers)
	_pincers.call("build", _body_size, _body_height(), _mat)
	print("[QUADRUPED] %d legs, body %.2fx%.2fx%.2f, segments %.2f/%.2f/%.2f, height %.2f (seed %d)"
			% [_legs.size(), _body_size.x, _body_size.y, _body_size.z,
			_leg_len * float(_fracs[0]), _leg_len * float(_fracs[1]),
			_leg_len * float(_fracs[2]), _body_height(), variation_seed])


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
		drop += _leg_len * float(_fracs[i]) * -cos(float(_angles[i]))
	# Sit LOWER by the amount the fore/aft stride shortens the leg's
	# vertical reach. The drop above is computed from the untilted rest
	# pose, but a walking leg is swung forward or back by up to
	# STEP_REACH — and a tilted leg does not reach as far down, which
	# left the feet hanging 0.27 m in the air (STO-ENEMIES-023).
	return maxf(-drop * cos(STEP_REACH * 0.75), 0.2)


func _build_leg(def: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(def["n"])
	var side: float = float(def["x"])
	var fore: float = float(def["z"])
	root.position = Vector3(
			side * _body_size.x * 0.5,
			_body_height(),
			fore * _body_size.z * 0.42)
	# NOTE (STO-ENEMIES-024, NOT DONE): a yaw of +/-45 degrees here was
	# meant to send each leg out along its own diagonal so the spider
	# reads as an X from above. Both signs were tried and neither
	# produced diagonals — the feet landed nearly axis-aligned and
	# asymmetric, so the legs are not splaying along their local X the
	# way this assumed. Reverted rather than left lopsided.
	add_child(root)

	# Each joint's rotation is the CHANGE from the previous segment's
	# angle, because they are nested — a delta, not the absolute angle.
	var parent := root
	var names := ["Upper", "Lower", "Foot"]
	var prev_angle := 0.0
	var last: Node3D = null
	var last_len := 0.0
	for i in SEGMENTS:
		var seg_len: float = _leg_len * float(_fracs[i])
		var angle: float = float(_angles[i])
		var joint := _make_segment(String(names[i]), seg_len)
		joint.rotation = Vector3(0.0, 0.0, side * (angle - prev_angle))
		if i > 0:
			joint.position = Vector3(0.0, -last_len, 0.0)
		parent.add_child(joint)
		parent = joint
		prev_angle = angle
		last = joint
		last_len = seg_len

	# The rest Z of each driven joint is recorded, because floppiness
	# has to be applied as rest+lag and NEVER as `rotation.z +=`. Adding
	# to a rotation every frame compounds it: the legs would wind
	# further round on every tick until the spider turned itself inside
	# out (STO-ENEMIES-037).
	var upper_node: Node3D = root.get_node("Upper")
	_legs.append({
		"root": root, "upper": upper_node, "lower": last,
		"pair": int(def["pair"]), "seg": last_len,
		"side": side,
		"rest_z_upper": upper_node.rotation.z,
		"rest_z_lower": last.rotation.z,
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


## How long its stride is, as a multiple of the one it was born with
## (STO-ENEMIES-043).
##
## This is the ONE dial its own mind is allowed to turn while it
## practises. Deliberately one, and deliberately clamped: a creature
## that could retune its whole body would sooner or later practise
## itself into being unable to walk, and a spider stuck twitching on
## the floor is a worse outcome than a spider that never improves.
func set_gait_scale(scale: float) -> void:
	_gait_scale = clampf(scale, 0.75, 1.35)


func gait_scale() -> float:
	return _gait_scale


func _process(delta: float) -> void:
	if _legs.is_empty():
		return
	_phase += delta * STEP_RATE * clampf(_speed / 3.0, 0.0, 2.0)
	for leg_i in _legs.size():
		var leg: Dictionary = _legs[leg_i]
		# Diagonal pairs are half a stride apart, so one diagonal is
		# always down while the other swings.
		var t: float = _phase + (0.5 if int(leg["pair"]) == 1 else 0.0)
		var p: float = fposmod(t, 1.0)
		# A real crawl, not a sine (STO-ENEMIES-023). A sine slides the
		# foot forward and back through the floor the whole time; a leg
		# that is CARRYING the creature must stay put while it pushes.
		#
		#   stance (0.0 - 0.6): foot planted, sweeping steadily BACK
		#   swing  (0.6 - 1.0): foot lifts and returns forward, fast
		# EVERY STEP IS DIFFERENT (STO-ENEMIES-026). Without this a
		# spider replays one identical stride forever, which is what
		# makes procedural walking read as a loop instead of a walk.
		#
		# Derived from (this spider's seed, which leg, which step), NOT
		# from randf(): the gait runs on every machine independently, so
		# a random number would give each peer a different-looking
		# spider. The same three inputs give the same step everywhere.
		var step_i: int = int(floor(t))
		# Jittered per PAIR, not per leg. Per-leg jitter desynchronised
		# the diagonals — and diagonal partners moving together is the
		# whole reason it is never left unsupported. Partners now take
		# the SAME varied step, and every step still differs.
		var j := _step_jitter(int(leg["pair"]), step_i)
		var lift_scale: float = 0.55 + 0.9 * j.x       # 0.55 - 1.45 high
		var reach_scale: float = 0.75 + 0.5 * j.y      # 0.75 - 1.25 long
		# Even the split between planted and swinging shifts, so some
		# steps are hurried and some are dragged.
		var stance: float = 0.5 + 0.2 * j.z            # 0.50 - 0.70

		var swing := 0.0
		var lift := 0.0
		if p < stance:
			swing = lerpf(1.0, -1.0, p / stance)  # planted, pushing back
		else:
			var q: float = (p - stance) / (1.0 - stance)
			swing = lerpf(-1.0, 1.0, q)           # reaching forward again
			lift = sin(q * PI)                    # and clear of the ground
		swing *= reach_scale * _gait_scale
		lift *= lift_scale
		var upper: Node3D = leg["upper"]
		var lower: Node3D = leg["lower"]
		# Applied ON TOP of the splayed rest pose, not instead of it —
		# overwriting the rotation would straighten the leg out of its
		# spider shape the moment it started walking.
		# Floppiness rides ON TOP of the gait (STO-ENEMIES-037), the
		# same way the gait rides on top of the splayed rest pose.
		# A limp limb stops driving and hangs instead: the gait fades
		# out and a droop fades in, so the leg goes dead rather than
		# freezing mid-stride.
		var limp01: float = clampf(_limp / LIMP_TIME, 0.0, 1.0)
		var live: float = 1.0 - limp01
		var leg_side: float = float(leg["side"])
		# The pose the gait ASKS for. What the leg actually does is a
		# spring chasing it, below.
		var want_up_x: float = swing * STEP_REACH * live \
				+ _flop.y * FLOP_NEAR + limp01 * LIMP_DROOP * 0.35
		var want_up_z: float = float(leg["rest_z_upper"]) \
				+ _flop.x * FLOP_NEAR * leg_side
		var want_lo_x: float = -lift * STEP_LIFT * 4.0 * live \
				+ _flop.y * FLOP_FAR + limp01 * LIMP_DROOP
		var want_lo_z: float = float(leg["rest_z_lower"]) \
				+ _flop.x * FLOP_FAR * leg_side

		# THE LIMB LAGS THE POSE IT IS TOLD TO HIT (STO-ENEMIES-039).
		#
		# STO-ENEMIES-037 hung floppiness off changes in the BODY's
		# velocity, which a spider walking in a steady line simply does
		# not have — it measured 1.4 degrees at peak and decayed to
		# nothing. The legs, meanwhile, are swinging the entire time it
		# walks. Trailing THOSE means the floppiness shows up exactly
		# when the creature is being looked at.
		#
		# The far joint is springier than the near one, so the end of
		# the limb whips behind the part near the socket.
		upper.rotation.x = _chase(leg, "ux", want_up_x, JOINT_STIFF_NEAR,
				JOINT_DAMP_NEAR, delta)
		upper.rotation.z = _chase(leg, "uz", want_up_z, JOINT_STIFF_NEAR,
				JOINT_DAMP_NEAR, delta)
		lower.rotation.x = _chase(leg, "lx", want_lo_x, JOINT_STIFF_FAR,
				JOINT_DAMP_FAR, delta)
		lower.rotation.z = _chase(leg, "lz", want_lo_z, JOINT_STIFF_FAR,
				JOINT_DAMP_FAR, delta)
		leg["want_lx"] = want_lo_x   # for tests: how far behind it runs


## The lag is worked out on the PHYSICS tick, not the render frame.
##
## Position only changes when physics runs. Sampled from _process, a
## render frame with no physics tick in it sees the creature as
## perfectly stationary and the next one sees it jump — so the velocity
## alternated between zero and a lurch, and the acceleration derived
## from it was enormous noise. A spider standing perfectly still measured 0.0325
## rad of lag it had no business having.
##
## Applied in _process, where the gait is drawn; only the measurement
## belongs here.
func _physics_process(delta: float) -> void:
	if _legs.is_empty():
		return
	_update_flop(delta)


## Work out how far the limbs should be trailing, and let a spring
## chase it (STO-ENEMIES-037).
##
## Driven by the creature's own ACCELERATION, measured from where it
## actually is rather than from anything it reports. Constant speed in a
## straight line is not something limbs lag behind — starting, stopping
## and turning are, and those are precisely what acceleration is. A
## spider standing still therefore has still legs, with no special case
## to say so.
func _update_flop(delta: float) -> void:
	if delta <= 0.0:
		return
	if _limp > 0.0:
		_limp -= delta

	# Velocity comes from the creature itself where it can, NOT from
	# differencing its position. Position differencing needs TWO
	# derivatives to reach acceleration, and each one multiplies the
	# noise by 1/delta: at 60 Hz a single millimetre of physics jitter
	# comes out as 3.6 m/s^2, which drove a spider standing perfectly
	# still to 0.07 rad of lag it had no business having.
	var vel := Vector3.ZERO
	var parent := get_parent()
	if parent is CharacterBody3D:
		vel = (parent as CharacterBody3D).velocity
	else:
		var here := global_position
		if _prev_pos == Vector3.INF:
			_prev_pos = here
		vel = (here - _prev_pos) / delta
		_prev_pos = here

	# Lag is driven by how far the current velocity has run ahead of a
	# SMOOTHED one — which is what starting, stopping and turning all
	# look like, and what steady travel does not. One derivative rather
	# than two, and bounded by real speed, so a stationary creature is
	# exactly zero rather than nearly zero.
	_vel_smooth = _vel_smooth.lerp(vel, clampf(FLOP_SMOOTH * delta, 0.0, 1.0))
	var change: Vector3 = vel - _vel_smooth
	change.y = 0.0

	# Into the creature's own frame, so "trailing behind" means behind
	# THIS spider rather than behind the world's -Z.
	var local_change: Vector3 = global_transform.basis.inverse() * change
	# Limbs lag OPPOSITE the change: shove the body forward and the legs
	# are left behind it.
	var target := Vector2(-local_change.x, -local_change.z) * FLOP_DRIVE
	target = target.limit_length(FLOP_MAX)

	var a: Vector2 = (target - _flop) * FLOP_STIFF - _flop_v * FLOP_DAMP
	_flop_v += a * delta
	_flop += _flop_v * delta
	_flop = _flop.limit_length(FLOP_MAX)

	if _pincers != null and _pincers.has_method("set_flop"):
		_pincers.call("set_flop", _flop)


## One joint's spring, chasing the angle the gait wants (039).
##
## State lives in the leg dictionary under `key`, so each joint keeps
## its own position and velocity. Returns where the joint actually is,
## which is behind where it was told to be — and that gap IS the
## floppiness.
func _chase(leg: Dictionary, key: String, want: float, stiff: float,
		damp: float, delta: float) -> float:
	var pos_key := "p_" + key
	var vel_key := "v_" + key
	if not leg.has(pos_key):
		leg[pos_key] = want     # start settled, not mid-swing
		leg[vel_key] = 0.0
	var pos: float = float(leg[pos_key])
	var vel: float = float(leg[vel_key])
	vel += ((want - pos) * stiff - vel * damp) * delta
	pos += vel * delta
	# Never let a joint fall further behind than this, or a spider spun
	# hard would wind its own leg round on itself.
	pos = clampf(pos, want - JOINT_LAG_MAX, want + JOINT_LAG_MAX)
	leg[pos_key] = pos
	leg[vel_key] = vel
	return pos


## How far the far joint is currently running behind the pose it was
## asked for, in radians. This is the number STO-ENEMIES-039 is about.
func gait_lag() -> float:
	var worst := 0.0
	for leg in _legs:
		if leg.has("p_lx") and leg.has("want_lx"):
			worst = maxf(worst, absf(float(leg["p_lx"]) - float(leg["want_lx"])))
	return worst


## Knock the life out of the limbs for a moment (STO-ENEMIES-037).
##
## They stop driving and hang. It reads as damage only because the
## limbs are already swinging loosely the rest of the time — a limb
## that stops moving stands out precisely because the others do not.
func go_limp(seconds := LIMP_TIME) -> void:
	_limp = maxf(_limp, seconds)
	if _pincers != null and _pincers.has_method("go_limp"):
		_pincers.call("go_limp", seconds)


## How limp the limbs are right now, 0 (working) to 1 (dangling).
func limpness() -> float:
	return clampf(_limp / LIMP_TIME, 0.0, 1.0)


## How far the limbs are currently trailing, for tests.
func flop() -> Vector2:
	return _flop


## Three repeatable "random" numbers in 0-1 for one leg's one step.
##
## Hashed from the spider's seed plus which leg and which step, so it
## is stable for that exact step on every machine — the same spider
## takes the same walk everywhere, while still never repeating itself.
func _step_jitter(pair_index: int, step_index: int) -> Vector3:
	var base: int = variation_seed * 73856093 + pair_index * 19349663 \
			+ step_index * 83492791
	var a: int = absi(hash(base))
	var b: int = absi(hash(base + 1))
	var c: int = absi(hash(base + 2))
	return Vector3(float(a % 1000) / 999.0,
			float(b % 1000) / 999.0,
			float(c % 1000) / 999.0)


## Where each foot is, in local space (for tests).
func foot_positions() -> Array:
	var out: Array = []
	for leg_i in _legs.size():
		var leg: Dictionary = _legs[leg_i]
		var lower: Node3D = leg["lower"]
		out.append(to_local(lower.global_transform * Vector3(0.0, -float(leg["seg"]), 0.0)))
	return out


## Where each KNEE is, in local space (for tests).
func knee_positions() -> Array:
	var out: Array = []
	for leg_i in _legs.size():
		var leg: Dictionary = _legs[leg_i]
		var lower: Node3D = leg["lower"]
		out.append(to_local(lower.global_position))
	return out


## How high the block rides, for tests.
func body_height() -> float:
	return _body_height()


## Stop drawing the animated legs (STO-ENEMIES-055).
##
## Once real physics bones exist they are the picture, and the animated
## chain becomes only the PLAN — where the gait would like the legs to
## be. Leaving both visible draws the spider twice: a ghost walking
## through walls inside a creature that cannot.
func hide_limbs() -> void:
	for leg in _legs:
		_hide_meshes(leg["root"] as Node3D)


func _hide_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).visible = false
	for c in n.get_children():
		_hide_meshes(c)


## Every limb segment, in WORLD space: {a, b, r} — the two ends of the
## bone and its radius (STO-ENEMIES-055).
##
## Exists so that whether the spider is solid can be MEASURED rather
## than judged by eye. Two previous attempts at limb collision were
## reverted, and the thing that made the second one honest was having
## numbers to compare — deepest limb inside a wall, and worst overlap
## between two legs. This is what produces them.
##
## Every segment of every leg, not just the ends: the failed attempts
## looked fine at the feet and were buried at the knee.
func limb_segments() -> Array:
	var out: Array = []
	var r: float = _leg_th * 0.5
	for leg in _legs:
		var node: Node3D = leg["root"]
		var names := ["Upper", "Lower", "Foot"]
		for i in SEGMENTS:
			node = node.get_node_or_null(String(names[i])) as Node3D
			if node == null:
				break
			var seg_len: float = _leg_len * float(_fracs[i])
			out.append({
				"a": node.global_position,
				"b": node.global_transform * Vector3(0.0, -seg_len, 0.0),
				"r": r,
				"leg": int(leg["pair"]),
				"name": "%s/%s" % [String((leg["root"] as Node3D).name),
						String(names[i])],
			})
	return out


## The pincer arms (STO-ENEMIES-030), or null on a body without them.
func pincers() -> Node3D:
	return _pincers


## This individual's segment lengths, body outward (for tests).
func segment_lengths() -> Array:
	var out: Array = []
	for f in _fracs:
		out.append(_leg_len * float(f))
	return out


func leg_count() -> int:
	return _legs.size()


func body_size() -> Vector3:
	return _body_size
