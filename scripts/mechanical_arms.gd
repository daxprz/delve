class_name MechanicalArms
extends Node3D
## The player's two large mechanical arms — procedurally built AND
## procedurally simulated (STO-CHARACTER-001 / 002 / 003).
##
## Each arm is a 3-part chain — UpperArm -> Forearm -> Hand (a fist) —
## driven by a procedural **Verlet** ragdoll solver (STO-CHARACTER-002):
## a small chain of points (shoulder, elbow, wrist, fingertip) that fall
## under gravity, keep their segment lengths, and drag behind the player
## as they move. No RigidBody — the whole ragdoll is generated in code,
## which keeps it stable and easy to tune.
##
## Grabbing (STO-CHARACTER-003): left mouse = left hand, right mouse =
## right hand. A ray from the centre of the screen (crosshair aim) finds a
## point; the hand latches onto it. Grabbing the movable box reels it in.
## Grabbing is JUST grabbing — there is no rope-swing grapple.
##
## All shape/behaviour values live here in one place.

## Names of the 3 arm parts, shoulder -> hand. Smoke tests rely on these.
const PART_NAMES: PackedStringArray = ["UpperArm", "Forearm", "Hand"]

## Global size multiplier for the whole arm.
@export var arm_scale: float = 1.0
## Shoulder anchor offset from player origin: sideways, height, fwd/back.
## Matches the humanoid body's shoulder joints so the arms attach there
## (instead of floating out wide at the sides).
@export var shoulder_offset: Vector3 = Vector3(0.28, 1.4, 0.0)

# --- Limb dimensions (metres, before arm_scale) ---
## Back to the original length (STO-CHARACTER-062). They were briefly
## lengthened to 1.20/1.05 so the hand could reach a distant carry
## point — but at 2.25 m the arms are LONGER THAN THE PLAYER IS TALL
## (shoulder at 1.40), so they hit the floor and crumpled, leaving the
## resting fist ABOVE the shoulder. The real fix was elsewhere: pull
## harder while carrying (CARRY_REACH_LERP) and hold the object in the
## palm, not on the hand's centre line.
const UPPER_LEN := 0.90
const UPPER_TH := 0.28
const FORE_LEN := 0.78
const FORE_TH := 0.22
const HAND_LEN := 0.34   # wrist -> knuckles (the palm block)
const FIST_TH := 0.40    # fists are chunky

# --- Fingers (STO-CHARACTER-057) -------------------------------------
## Five fingers per hand, laid out like a human one — pointer, middle,
## ring, pinky in a row, with the thumb apart and opposing them.
##
## They are all the SAME LENGTH, which is the one deliberate departure
## from a real hand (where the middle finger is longest). The operator
## asked for equal lengths so the hand reads as mechanical rather than
## as a copy of a human one — which suits the Grabber: these are built
## arms, not grown ones.
const FINGER_NAMES: PackedStringArray = ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]
const THUMB_INDEX := 4
## 2 joints per finger => 3 segments, base -> middle -> tip.
const FINGER_SEGMENTS := 3
const FINGER_LEN := 0.30          # total length, same for every finger
## Chunky mechanical fingers (STO-CHARACTER-061) — these are built
## arms, not delicate ones.
##
## Thickness and spread are ONE decision, not two: thicker fingers
## clip into each other unless the spread grows with them, which is
## the exact fault STO-CHARACTER-058 fixed. Both moved together here,
## and 058's no-clip test is what proves it.
const FINGER_TH := 0.090
## How far the whole hand span reaches across, for spacing the four.
## Widened alongside FINGER_TH so the gap between fingers survives
## them getting chunkier (STO-CHARACTER-061).
const FINGER_SPREAD := 0.42
## Knuckles sit BELOW the middle of the palm block, so a closing
## finger curls in front of the palm rather than through it.
const FINGER_KNUCKLE_Y := -0.12
## The thumb sits BELOW the palm's lower face, not inside it. Measured
## the hard way (STO-CHARACTER-058): from the middle of the palm its
## curl swept from x -0.22 to -0.04, straight through the block. A real
## thumb closes ACROSS the palm's front surface, and this puts it
## there. FIST_TH * 0.5 is that surface; the rest is clearance.
const THUMB_KNUCKLE_Y := -0.24
## A thumb curls LESS than a finger — true of real hands, and here it
## also stops the tilted curl plane carrying the tip back up into the
## palm past halfway (STO-CHARACTER-058).
const THUMB_CURL_SCALE := 0.42
## Curl the hand settles at when it is holding nothing — fingers hang
## slightly relaxed rather than rigidly splayed.
const REST_CURL := 0.18
## Curl of a clenched fist in punch mode (STO-CHARACTER-060).
const FIST_CURL := 1.0
## Gripping something solid — a wall — closes the hand most of the way.
const ANCHOR_CURL := 0.8
## How fast the hand opens and closes, in curl per second. Fast enough
## to feel responsive, slow enough that switching modes is a motion
## rather than a snap (STO-CHARACTER-060).
const CURL_SPEED := 6.0
## An object of this radius or more keeps the fingers fully open; a
## point-sized one lets them close completely (STO-CHARACTER-059).
const GRIP_OPEN_RADIUS := 0.55
## However big the thing is, keep some bend — a dead-flat hand reads
## as not holding anything.
const GRIP_MIN_CURL := 0.12
## How finely each finger sweeps for the object's surface. 16 steps is
## about 6 degrees of knuckle per step — finer than anyone can see.
const CONTACT_STEPS := 16
## How far short of the surface a fingertip stops (STO-CHARACTER-064).
##
## Was 0.045 — plus the sweep stopping one whole step early, that left
## a visible gap and a held crate looked like it was floating in a
## claw. Halving the step-back closed most of that gap.
##
## The margin itself went 0.045 -> 0.02 and had to come back to 0.035:
## at 0.02 a fingertip had to get so close that it MISSED a swinging
## ragdoll altogether, and smoke_wrap_ragdoll went from 4/4 to 2/4. A
## grip that looks a millimetre better but lets go of a moving body is
## a bad trade.
const CONTACT_MARGIN := 0.035
## How far below the hand's centre line a held object rests — the palm
## side, where the fingers actually close.
const GRIP_PALM_Y := -0.20
## How far each joint bends at full curl, base -> tip. The base knuckle
## bends least: a finger whose joints all bend equally curls into a
## hoop rather than a fist.
##
## Totals 155 degrees, not the 212 it started at (STO-CHARACTER-058).
## At 212 the fingertip ended up INSIDE the palm block — measured, not
## guessed: tip y -0.101 against a palm spanning y +/-0.20. A finger
## that folds through its own hand is the exact thing the operator
## asked to prevent.
const FINGER_CURL_MAX: Array = [0.75, 1.00, 0.95]

# --- Verlet ragdoll tuning ---
const GRAVITY := Vector3(0.0, -12.0, 0.0)
const DAMPING := 0.96        # 1.0 = frictionless, lower = heavier/draggier
const SOLVER_ITERATIONS := 16  # more = stiffer segments that never pull apart
const FLOOR_Y := 0.06        # ground plane top (main.tscn ground at y=0)
const CHAIN_MARGIN := 0.06   # how far a chain link is kept off a surface it hits
## How fast a grabbing hand reaches its target. Low = heavy (eases over
## several frames) instead of snapping there instantly.
const GRAB_REACH_LERP := 0.18
## While CARRYING something the hand pulls to its target much harder.
## Easing at 0.18 never arrived: gravity drags the chain down every
## tick, so the hand sat short and the held object hung beyond the
## fingertips. An arm holding something braces; it does not dangle.
const CARRY_REACH_LERP := 0.55

# --- Grab tuning ---
const GRAB_REACH := 3.0        # how far a hand can reach to grab (short reach)
## Grabbing something solid hauls the player toward it (a real
## grapple) — acceleration in m/s^2, and how close counts as arrived.
const SELF_PULL := 26.0
const SELF_PULL_STOP := 1.1

# --- Ram tuning (STO-CHARACTER-021) ---
# In punch mode you hold the button to stick the fist STRAIGHT OUT; running
# an extended fist into an enemy deals damage scaled by your momentum.
const ShockwaveScript := preload("res://scripts/shockwave.gd")
const RAM_MIN_SPEED := 3.0          # need at least this much speed to hurt
const RAM_DAMAGE_SCALE := 2.2       # enemy damage per m/s of momentum
const RAM_HIT_RADIUS := 0.9         # how close the fist must get
## Punch knockback (STO-CHARACTER-045). A landed punch has to be able
## to knock an enemy DOWN: the enemy ragdoll threshold is ~7.5 of
## delivered dv, and the old `speed * 0.35` only ever reached ~1.75 at
## a run, so punches could never do more than nudge. Now there is a
## solid base hit plus a momentum bonus, so a slow ram staggers and a
## fast one flattens them.
## Sized so a punch floors even the sturdiest procedural build: the
## worst case needs impulse >= KNOCKDOWN_DV(7.5) * stability(1.25) *
## mass(1.5) ~= 14. At a 5 m/s ram that is 6.0 + 8.0 = 14, and a
## sprint puts it well clear; a minimum-speed ram still staggers.
const RAM_KNOCKBACK_BASE := 6.0     # landed-punch impulse regardless of speed
const RAM_KNOCKBACK := 1.6          # extra knockback per m/s of momentum
const RAM_KNOCKBACK_LIFT := 0.35    # how much of the hit goes upward
## Hauling a grabbed enemy along (STO-CHARACTER-045): a limp body is
## ~60 kg of jointed parts, so the box's gentle reel impulse could not
## shift it. Steer the held part toward a carry point instead.
## How far in front a grabbed body is carried (STO-CHARACTER-054:
## raised from 1.6, which hauled it in against the player).
const HOLD_DIST := 2.4
const HOLD_STIFFNESS := 11.0
const HOLD_MAX_SPEED := 16.0
const RAM_SHOCKWAVE_SPEED := 9.0    # momentum needed for a shockwave on a ram hit
const RAM_COOLDOWN := 0.4           # per-enemy, so one ram = ~one hit

var _ram_cd: Dictionary = {}
## In punch mode the fists are held out in a ready guard in front of the
## player (STO-CHARACTER-007), instead of dangling.
const GUARD_LERP := 0.16           # how firmly the fist holds the punch reach

var _player  # the parent Player (untyped for dynamic property access)
var _camera: Camera3D
var _metal: StandardMaterial3D
var _joint_mat: StandardMaterial3D
var _fist_mat: StandardMaterial3D

# One entry per arm. Each: {
#   side:int, button:int, root:Node3D,
#   points:PackedVector3Array, prev:PackedVector3Array, lengths:Array,
#   grabbed:bool, target:Vector3, was_pressed:bool, grabbed_body }
var _arms: Array = []

## Grab mode vs punch mode (STO-CHARACTER-007). In punch mode the hands
## can't grab — a click throws a momentum punch instead.
var _punch_mode := false
## How many shockwaves this pair of arms has spawned (for tests).
var _shockwaves := 0


func _ready() -> void:
	_player = get_parent()
	if _player != null:
		_camera = _player.get_node_or_null("Camera3D") as Camera3D

	_metal = _make_material(Color(0.55, 0.58, 0.62), 0.9, 0.35)
	_joint_mat = _make_material(Color(0.30, 0.32, 0.36), 1.0, 0.25)
	_fist_mat = _make_material(Color(0.62, 0.64, 0.68), 0.95, 0.3)

	_make_arm(0, -1, MOUSE_BUTTON_LEFT, "ArmLeft")    # left arm, LMB
	_make_arm(1, 1, MOUSE_BUTTON_RIGHT, "ArmRight")   # right arm, RMB
	_make_plate()

	print("[ARMS] built 2 procedural ragdoll arms, 3 parts each "
			+ "(upper arm + forearm + fist), scale %.2f" % arm_scale)


## The piston\'s face: a big flat block, like a small shield — wider
## than it is thick, and clearly not two fists (STO-CHARACTER-073).
## Hidden until the arms fold into piston mode.
func _make_plate() -> void:
	# A solid body, not decoration (STO-CHARACTER-073): the plate is a
	# real obstacle in the world, so it shoves what it meets by being
	# there rather than by a check.
	_plate = AnimatableBody3D.new()
	_plate.name = "PistonPlate"
	_plate.top_level = true          # placed in world space, like the arms
	_plate.visible = false
	add_child(_plate)

	var col := CollisionShape3D.new()
	var cb := BoxShape3D.new()
	cb.size = Vector3(PLATE_W, PLATE_H, PLATE_T) * arm_scale
	col.shape = cb
	_plate.add_child(col)

	var dark := _make_material(Color(0.26, 0.28, 0.33), 1.0, 0.45)

	# The face itself.
	var face := MeshInstance3D.new()
	face.name = "Face"
	var fb := BoxMesh.new()
	fb.size = Vector3(PLATE_W, PLATE_H, PLATE_T) * arm_scale
	face.mesh = fb
	face.material_override = _metal
	_plate.add_child(face)

	# Mechanical clutter so it reads as built rather than as a slab:
	# a rim, a central boss, and four bolts.
	var rim := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(PLATE_W * 1.08, PLATE_H * 1.08, PLATE_T * 0.45) * arm_scale
	rim.mesh = rb
	rim.material_override = dark
	rim.position = Vector3(0.0, 0.0, -PLATE_T * 0.4 * arm_scale)
	_plate.add_child(rim)

	var boss := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = PLATE_H * 0.22 * arm_scale
	bc.bottom_radius = PLATE_H * 0.28 * arm_scale
	bc.height = PLATE_T * 1.5 * arm_scale
	boss.mesh = bc
	boss.material_override = _joint_mat
	boss.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	boss.position = Vector3(0.0, 0.0, PLATE_T * 0.5 * arm_scale)
	_plate.add_child(boss)

	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var bolt := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.045 * arm_scale
			bm.bottom_radius = 0.045 * arm_scale
			bm.height = PLATE_T * 1.2 * arm_scale
			bolt.mesh = bm
			bolt.material_override = _joint_mat
			bolt.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			bolt.position = Vector3(sx * PLATE_W * 0.36 * arm_scale,
					sy * PLATE_H * 0.34 * arm_scale,
					PLATE_T * 0.4 * arm_scale)
			_plate.add_child(bolt)


func _make_material(color: Color, metallic: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	return m


# ---------------------------------------------------------------------
# Build (procedural generation of the arm meshes)
# ---------------------------------------------------------------------

func _make_arm(index: int, side: int, button: int, arm_name: String) -> void:
	var root := Node3D.new()
	root.name = arm_name
	root.top_level = true   # positioned in world space by the solver
	add_child(root)

	# Visual parts (positioned every frame by the solver).
	var upper := _make_limb("UpperArm", UPPER_LEN, UPPER_TH)
	var fore := _make_limb("Forearm", FORE_LEN, FORE_TH)
	var hand := _make_fist()
	root.add_child(upper)
	root.add_child(fore)
	root.add_child(hand)

	var lengths := [UPPER_LEN * arm_scale, FORE_LEN * arm_scale, HAND_LEN * arm_scale]

	# Initialise the 4 ragdoll points hanging straight down from the shoulder.
	var shoulder := _shoulder_world(side)
	var pts := PackedVector3Array()
	pts.append(shoulder)
	pts.append(shoulder + Vector3.DOWN * lengths[0])
	pts.append(shoulder + Vector3.DOWN * (lengths[0] + lengths[1]))
	pts.append(shoulder + Vector3.DOWN * (lengths[0] + lengths[1] + lengths[2]))

	_arms.append({
		"index": index, "side": side, "button": button, "root": root,
		"points": pts, "prev": pts.duplicate(), "lengths": lengths,
		"grabbed": false, "target": Vector3.ZERO, "was_pressed": false,
		"grabbed_body": null, "grabbed_enemy": null,
		"extended": false, "force_extend": false, "curl": REST_CURL,
	})


func _make_limb(part_name: String, length: float, thickness: float) -> Node3D:
	var part := Node3D.new()
	part.name = part_name
	_add_joint(part, thickness)
	var seg := MeshInstance3D.new()
	seg.name = "Segment"
	var box := BoxMesh.new()
	box.size = Vector3(thickness, thickness, length) * arm_scale
	seg.mesh = box
	seg.material_override = _metal
	seg.position = Vector3(0.0, 0.0, length * 0.5 * arm_scale)
	part.add_child(seg)
	return part


func _make_fist() -> Node3D:
	# A chunky fist: a wrist joint, a big knuckle block, and 4 knuckle
	# ridges on top (no separate fingers — it's a closed fist).
	var hand := Node3D.new()
	hand.name = "Hand"
	_add_joint(hand, FIST_TH)

	var fist := MeshInstance3D.new()
	fist.name = "Fist"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(FIST_TH, FIST_TH, HAND_LEN) * arm_scale
	fist.mesh = fbox
	fist.material_override = _fist_mat
	fist.position = Vector3(0.0, 0.0, HAND_LEN * 0.5 * arm_scale)
	hand.add_child(fist)

	_add_fingers(hand)
	return hand


## Build the five fingers onto a hand (STO-CHARACTER-057).
##
## Each finger is a nested chain — Base -> J1 -> Mid -> J2 -> Tip —
## so curling is just rotating the two joint nodes. Nesting means a
## rotation at J1 carries everything past it, exactly as a real finger
## does, instead of each segment having to be placed by hand.
func _add_fingers(hand: Node3D) -> void:
	var fingers := Node3D.new()
	fingers.name = "Fingers"
	hand.add_child(fingers)

	var spread := FINGER_SPREAD * arm_scale
	var knuckle_z := HAND_LEN * arm_scale
	for i in FINGER_NAMES.size():
		var finger := _make_finger(String(FINGER_NAMES[i]))
		if i == THUMB_INDEX:
			# The thumb sits back along the palm and OPPOSES the rest,
			# so the hand can close ON something rather than flapping
			# four fingers at it.
			finger.position = Vector3(-spread * 0.55,
					THUMB_KNUCKLE_Y * arm_scale, knuckle_z * 0.45)
			finger.rotation = Vector3(0.0, 0.0, deg_to_rad(-72.0))
		else:
			# Pointer -> pinky, evenly across the knuckle line.
			var t := float(i) / float(FINGER_NAMES.size() - 2)
			finger.position = Vector3(lerpf(spread * 0.42, -spread * 0.42, t),
					FINGER_KNUCKLE_Y * arm_scale, knuckle_z)
		fingers.add_child(finger)


## One finger: FINGER_SEGMENTS segments in a nested chain, every finger
## the same total length.
func _make_finger(finger_name: String) -> Node3D:
	var seg_len := FINGER_LEN * arm_scale / float(FINGER_SEGMENTS)
	var th := FINGER_TH * arm_scale

	var root := Node3D.new()
	root.name = finger_name
	var parent := root
	for s_i in FINGER_SEGMENTS:
		# Joint nodes are what get rotated to curl the finger; the
		# meshes hang off them and never move on their own.
		var joint := Node3D.new()
		joint.name = "J%d" % s_i
		parent.add_child(joint)

		# No knuckle sphere per segment (STO-CHARACTER-061): 5 fingers
		# x 3 segments x 2 hands was 30 spheres per player, at a size
		# where nobody can see them.
		var seg := MeshInstance3D.new()
		seg.name = "Seg"
		var sbox := BoxMesh.new()
		sbox.size = Vector3(th, th, seg_len)
		seg.mesh = sbox
		seg.material_override = _fist_mat if s_i == 0 else _metal
		seg.position = Vector3(0.0, 0.0, seg_len * 0.5)
		joint.add_child(seg)

		# The next joint starts at the end of this segment.
		var tip := Node3D.new()
		tip.name = "End"
		tip.position = Vector3(0.0, 0.0, seg_len)
		joint.add_child(tip)
		parent = tip
	return root


## Curl one finger. `t` is 0 (straight) to 1 (fully closed) — the
## single number every later story in EPI-CHARACTER-FINGERS drives:
## wrapping around a grabbed object, clenching in punch mode, and the
## limits that stop it reaching impossible shapes.
##
## The base knuckle bends less than the two joints past it, which is
## what makes a curling finger look like a finger rather than a hoop.
func set_finger_curl(finger: Node3D, t: float) -> void:
	if finger == null:
		return
	# Clamped at BOTH ends (STO-CHARACTER-058): below 0 a finger would
	# bend backwards past straight, which no hand does; above 1 it
	# would fold through the palm.
	var c := clampf(t, 0.0, 1.0)
	if finger.name == "Thumb":
		c *= THUMB_CURL_SCALE
	var node: Node3D = finger
	for s_i in FINGER_SEGMENTS:
		var joint := node.get_node_or_null("J%d" % s_i) as Node3D
		if joint == null:
			return
		joint.rotation.x = -c * FINGER_CURL_MAX[s_i]
		node = joint.get_node_or_null("End") as Node3D
		if node == null:
			return


## Curl every finger on a hand to the same amount.
func set_hand_curl(arm_index: int, t: float) -> void:
	var f := fingers_root(arm_index)
	if f == null:
		return
	for finger in f.get_children():
		set_finger_curl(finger as Node3D, t)


## How closed a hand currently is, 0 (straight) to 1 (clenched).
func hand_curl(arm_index: int) -> float:
	if arm_index < 0 or arm_index >= _arms.size():
		return 0.0
	return float(_arms[arm_index].get("curl", REST_CURL))


## How closed ONE finger currently is (STO-CHARACTER-062: each finger
## has its own).
func finger_curl(arm_index: int, finger_name: String) -> float:
	if arm_index < 0 or arm_index >= _arms.size():
		return 0.0
	var curls: Dictionary = _arms[arm_index].get("curls", {})
	return float(curls.get(finger_name, REST_CURL))


## The Fingers node of an arm's hand, or null.
func fingers_root(arm_index: int) -> Node3D:
	if arm_index < 0 or arm_index >= _arms.size():
		return null
	var root: Node3D = _arms[arm_index]["root"]
	var hand := root.get_node_or_null("Hand") as Node3D
	return hand.get_node_or_null("Fingers") as Node3D if hand != null else null


## A named finger on an arm ("Pointer", "Thumb", ...), or null.
func finger(arm_index: int, finger_name: String) -> Node3D:
	var f := fingers_root(arm_index)
	return f.get_node_or_null(finger_name) as Node3D if f != null else null


func _add_joint(part: Node3D, thickness: float) -> void:
	var joint := MeshInstance3D.new()
	joint.name = "Joint"
	var sphere := SphereMesh.new()
	var r := thickness * 0.7 * arm_scale
	sphere.radius = r
	sphere.height = r * 2.0
	joint.mesh = sphere
	joint.material_override = _joint_mat
	part.add_child(joint)


# ---------------------------------------------------------------------
# Simulate (procedural Verlet ragdoll) — STO-CHARACTER-002 / 003
# ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _is_authority():
		_update_grab_input()

	# Ease into and out of the piston shape, so the change is a motion
	# rather than a snap (STO-CHARACTER-073).
	var want: float = 1.0 if _mode == MODE_PISTON else 0.0
	_piston_blend = move_toward(_piston_blend, want, PISTON_BLEND_RATE * delta)
	# Heavy things do not turn on a sixpence: the piston's aim chases
	# the camera instead of matching it (STO-CHARACTER-073).
	var goal := aim_dir().normalized()
	if _piston_blend > 0.01:
		_piston_aim = _piston_aim.slerp(goal, clampf(PISTON_TURN_LAG * delta, 0.0, 1.0))
		if _piston_aim.length() < 0.01:
			_piston_aim = goal
		_piston_aim = _piston_aim.normalized()
	else:
		_piston_aim = goal              # snaps back when not in the mode
	_update_plate()
	# The fingers go away in piston mode (STO-CHARACTER-073): the
	# hands are one machine now, not two hands with digits.
	var show_fingers: bool = _piston_blend < 0.5
	for i in range(_arms.size()):
		var f := fingers_root(i)
		if f != null and f.visible != show_fingers:
			f.visible = show_fingers
	if _mode == MODE_PISTON:
		_update_piston_stroke(delta)
	for arm_v in _arms:
		var arm: Dictionary = arm_v
		_simulate_arm(arm, delta)
		_apply_grab_pull(arm)
		_update_curl(arm, delta)
		_update_visual(arm)

	# Ramming an extended fist into enemies with momentum hurts them.
	if _punch_mode and _is_authority():
		_ram_damage(delta)


func _simulate_arm(arm: Dictionary, delta: float) -> void:
	var pts: PackedVector3Array = arm["points"]
	var prev: PackedVector3Array = arm["prev"]
	var lengths: Array = arm["lengths"]
	var shoulder := _shoulder_world(int(arm["side"]))
	var grabbed: bool = arm["grabbed"]
	var g := GRAVITY * delta * delta
	var last := pts.size() - 1

	# Integrate every point except the pinned shoulder. Verlet carries
	# momentum, which (with the drag above) gives the arm its weight.
	for i in range(pts.size()):
		if i == 0:
			continue
		var cur := pts[i]
		pts[i] = cur + (cur - prev[i]) * DAMPING + g
		prev[i] = cur

	# Heavy grab: EASE the fingertip toward the grab point instead of
	# snapping it there. It reaches over several frames, and if the point
	# is out of reach the arm just stretches toward it — the length
	# constraints below still keep it in one solid piece.
	if grabbed:
		var target: Vector3 = arm["target"]
		var reach_lerp := GRAB_REACH_LERP
		if arm["grabbed_body"] != null and is_instance_valid(arm["grabbed_body"]):
			reach_lerp = CARRY_REACH_LERP
		pts[last] += (target - pts[last]) * reach_lerp
	elif _piston_blend > 0.01:
		# PISTON MODE: both hands are pulled to the SAME point, so the
		# two arms visibly converge and lock together into one shaft
		# (STO-CHARACTER-070). Scaled by the blend so they FOLD in and
		# unfold out rather than snapping (STO-CHARACTER-073) — and the
		# blend outlasts the mode, so leaving it eases apart too.
		var joined := _piston_point()
		pts[last] += (joined - pts[last]) * PISTON_JOIN_LERP * _piston_blend
		# Gravity must not sag the arms back down between strokes: in
		# piston mode they are HELD out, machinery under power rather
		# than limbs hanging.
		prev[last] = pts[last]
		# Pull the elbow inward too, or the arms meet at the hands
		# while their middles still bow out to the sides.
		var elbow := _shoulder_world(int(arm["side"])).lerp(joined, 0.5)
		pts[last - 1] += (elbow - pts[last - 1]) \
				* PISTON_JOIN_LERP * 0.6 * _piston_blend
	elif _punch_mode and arm["extended"]:
		# Punch mode: the arms hang loose at your sides — no raised
		# guard pose (STO-CHARACTER-031). Only while the button is HELD
		# does the fist stick straight out in front (the ram pose).
		var target := _reach_point(int(arm["side"]))
		pts[last] += (target - pts[last]) * GUARD_LERP

	# Relaxation: ONLY the shoulder is a hard pin. Segment lengths are
	# enforced exactly, so the arm bends at its joints but never pulls
	# apart into separate pieces — solid, but jointed.
	for _iter in SOLVER_ITERATIONS:
		pts[0] = shoulder
		for s in range(lengths.size()):
			var a := s
			var b := s + 1
			var delta_v := pts[b] - pts[a]
			var dist := delta_v.length()
			if dist < 1e-5:
				continue
			var diff: float = (dist - float(lengths[s])) / dist
			if a == 0:
				pts[b] -= delta_v * diff
			else:
				pts[a] += delta_v * 0.5 * diff
				pts[b] -= delta_v * 0.5 * diff
		for i in range(pts.size()):
			if pts[i].y < FLOOR_Y:
				pts[i].y = FLOOR_Y

	# Collide the chain with ALL solid geometry (walls, pillars, box,
	# enemies) — not just the floor. Each link that crosses a surface is
	# pulled back to rest against it.
	_collide_chain(pts, prev)

	arm["points"] = pts
	arm["prev"] = prev


## Keep each chain point from crossing solid geometry: ray-check each
## link from its joint to its far point and clamp to the first surface.
func _collide_chain(pts: PackedVector3Array, prev: PackedVector3Array) -> void:
	var space := get_world_3d().direct_space_state
	for i in range(1, pts.size()):
		if pts[i - 1].distance_to(pts[i]) < 1e-4:
			continue
		var q := PhysicsRayQueryParameters3D.create(pts[i - 1], pts[i])
		if _player != null:
			q.exclude = [_player.get_rid()]
		var chit := space.intersect_ray(q)
		if not chit.is_empty():
			var pos: Vector3 = chit["position"]
			var nrm: Vector3 = chit["normal"]
			pts[i] = pos + nrm * CHAIN_MARGIN
			prev[i] = pts[i]  # kill velocity into the surface (rest against it)


func _apply_grab_pull(arm: Dictionary) -> void:
	if not arm["grabbed"] or _player == null:
		return
	var shoulder := _shoulder_world(int(arm["side"]))
	var body = arm["grabbed_body"]
	var enemy = arm.get("grabbed_enemy")

	# Holding a limp enemy: haul the whole body along by steering the
	# held part toward a carry point in front of the shoulder. An
	# impulse-based reel cannot move ~60 kg of jointed ragdoll.
	if enemy != null and is_instance_valid(enemy) \
			and body != null and is_instance_valid(body) and body is RigidBody3D:
		# A limp enemy is hauled to a PLAYER-relative point, not a
		# hand-relative one. The hand lags as it swings, so steering
		# 60 kg of jointed body toward a point that is itself lagging
		# compounded the delay and the body trailed further and further
		# behind (STO-CHARACTER-063). The fingers still find it: the
		# palm now turns to face whatever it holds.
		var carry := _carry_point(shoulder)
		var to_carry: Vector3 = carry - (body as RigidBody3D).global_position
		var v: Vector3 = to_carry * HOLD_STIFFNESS
		if v.length() > HOLD_MAX_SPEED:
			v = v.normalized() * HOLD_MAX_SPEED
		(body as RigidBody3D).linear_velocity = v
		# Aim the knuckles a palm's depth SHORT of the body, not at its
		# centre. Aimed dead at it, the body sat on the hand's centre
		# line while the fingers swept below — they closed on nothing
		# and every finger reached full curl (STO-CHARACTER-063). The
		# palm already turns to face it, so backing off along the line
		# to the hand puts the body squarely in the fingers' arc.
		var bpos: Vector3 = (body as RigidBody3D).global_position
		var back := shoulder - bpos
		back = back.normalized() if back.length() > 0.001 else Vector3.UP
		arm["target"] = bpos + back * (absf(GRIP_PALM_Y) * arm_scale)
		return

	if body != null and is_instance_valid(body) and body is RigidBody3D:
		# Grabbed a loose body (a crate): PICK IT UP and hold it OUT IN
		# FRONT (STO-CHARACTER-055, superseding 053).
		#
		# Steered to a carry point rather than shoved with impulses.
		# The original version fired an impulse at the shoulder every
		# tick, so the crate accelerated at the player, overshot,
		# bounced off and got yanked back — never settling, and its
		# leftover speed was added to every throw. Steering to a fixed
		# point in front holds it still, which is what makes a throw
		# repeatable AND keeps it out of the way of your aim.
		var rb := body as RigidBody3D
		# Hold it where the HAND actually is, not where the camera
		# wishes it were (STO-CHARACTER-062).
		#
		# Steering it to a camera-relative point left it floating 0.75 m
		# BEYOND the fingertips: the arm is a hanging Verlet chain that
		# never fully straightens, so the hand always lagged the point
		# it was aiming at, and the fingers had nothing within reach to
		# close on. Taking the carry point from the hand's own knuckles
		# means the object is always in the fingers' arc — and follows
		# the hand exactly as the player moves, which is the point.
		# Hand AND object aim at the SAME point, now that the arm is
		# long enough to get there (STO-CHARACTER-062). While it was
		# too short these had to differ, and the object ended up
		# floating beyond the fingertips with nothing to close on.
		# The ARM aims out in front at eye level; the OBJECT sits in the
		# palm, on the side the fingers curl toward.
		arm["target"] = _carry_point(shoulder)
		var carry_p := _grip_point(arm)
		var to_c: Vector3 = carry_p - rb.global_position
		var vel: Vector3 = to_c * HOLD_STIFFNESS
		if vel.length() > HOLD_MAX_SPEED:
			vel = vel.normalized() * HOLD_MAX_SPEED
		rb.linear_velocity = vel
		return

	# Grabbed something SOLID (wall, pillar, floor): the arm reels the
	# PLAYER in toward the anchor — the Grabber actually pulls himself
	# (STO-CHARACTER-044). Handed to the player as an acceleration so
	# it survives the walk input, which rewrites velocity every tick.
	var anchor: Vector3 = arm["target"]
	var to_anchor := anchor - shoulder
	var d := to_anchor.length()
	if d > SELF_PULL_STOP:
		_player.grapple_pull += to_anchor / d * SELF_PULL


## Where a held thing sits: in the PALM, on the side the fingers curl
## toward (STO-CHARACTER-062).
##
## Held on the hand's centre line it ended up at y +0.09 while the
## fingers swept from -0.12 down to -0.33 — they passed underneath it
## and never touched, which is why a big crate and a small block closed
## the fingers identically. A hand holds things against its palm, and
## the palm is the finger side.
##
## Taken from the hand's own transform, so it follows the hand exactly
## as the player moves, turns and looks around.
func _grip_point(arm: Dictionary) -> Vector3:
	var root: Node3D = arm["root"]
	var hand := root.get_node_or_null("Hand") as Node3D
	if hand == null:
		return _palm_point(arm)
	return hand.global_transform * Vector3(0.0,
			GRIP_PALM_Y * arm_scale,
			(HAND_LEN + FINGER_LEN * 0.38) * arm_scale)


## Just past the knuckles, in the fingers' arc — taken from the arm's
## own chain, so it is where the hand IS this tick rather than where it
## is heading.
func _palm_point(arm: Dictionary) -> Vector3:
	var pts: PackedVector3Array = arm["points"]
	var wrist: Vector3 = pts[2]
	var knuckles: Vector3 = pts[3]
	var dir := knuckles - wrist
	dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	return knuckles + dir * (FINGER_LEN * 0.45 * arm_scale)


## Where a held thing floats: out in front of the EYE, not the hips.
##
## Taken from the camera so it sits at eye level and follows the look
## direction up and down. It used to be the player's flattened facing
## from the shoulder, which meant looking up or down left the held
## object stubbornly at hip height — in the way of the very aim you
## were lining up (STO-CHARACTER-054/055).
func _carry_point(shoulder: Vector3) -> Vector3:
	if _camera != null and is_instance_valid(_camera):
		return _camera.global_position - _camera.global_transform.basis.z * HOLD_DIST
	var fwd: Vector3 = -_player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	return shoulder + fwd * HOLD_DIST


## Drive the fingers each tick (STO-CHARACTER-059 / 060).
##
## One number decides the whole hand shape, and where it comes from
## says what the hand is doing:
##   punch mode        -> clenched fist
##   holding an object -> wrapped around it, loosely for a big one
##   gripping a wall   -> closed hard
##   holding nothing   -> relaxed
##
## Eased toward rather than set, so changing mode is a motion.
func _update_curl(arm: Dictionary, delta: float) -> void:
	var idx := int(arm["index"])
	var f := fingers_root(idx)
	if f == null:
		return
	var body = arm["grabbed_body"] if bool(arm["grabbed"]) else null
	var holding: bool = body != null and is_instance_valid(body)
	var curls: Dictionary = arm.get("curls", {})

	var sum := 0.0
	var n := 0
	for child in f.get_children():
		var finger := child as Node3D
		if finger == null:
			continue
		var target := REST_CURL
		if _punch_mode:
			target = FIST_CURL
		elif holding:
			# EVERY finger works out its OWN curl by sweeping until its
			# tip meets the object (STO-CHARACTER-062). Recomputed every
			# tick, so moving or turning re-fits the hand instead of
			# dragging a pose decided when you grabbed it.
			target = _contact_curl(finger, body as Node3D)
		elif bool(arm["grabbed"]):
			target = ANCHOR_CURL          # latched onto solid geometry
		var cur := float(curls.get(finger.name, REST_CURL))
		cur = move_toward(cur, target, CURL_SPEED * delta)
		curls[finger.name] = cur
		set_finger_curl(finger, cur)
		sum += cur
		n += 1
	arm["curls"] = curls
	# Kept for anything that wants one number for the whole hand.
	arm["curl"] = sum / float(n) if n > 0 else REST_CURL


## How far this finger can close before its tip meets `body`
## (STO-CHARACTER-062).
##
## Sweeps the curl and stops one step before the fingertip would be
## inside the object. Nothing is authored per object: the answer comes
## from the object's own collision shape, so a bar, a crate and a
## ragdoll all just work.
func _contact_curl(finger: Node3D, body: Node3D) -> float:
	if body == null:
		return REST_CURL
	for step in range(1, CONTACT_STEPS + 1):
		var t := float(step) / float(CONTACT_STEPS)
		if _point_in_body(body, _tip_world(finger, t)):
			# Half a step back, not a whole one: a full step left the
			# tip visibly short of what it was holding
			# (STO-CHARACTER-064).
			return maxf((float(step) - 0.5) / float(CONTACT_STEPS),
					GRIP_MIN_CURL)
	return 1.0


## Where this finger's tip would be at curl `t`, without moving
## anything — the joint angles are the same ones set_finger_curl uses.
func _tip_world(finger: Node3D, t: float) -> Vector3:
	var c := clampf(t, 0.0, 1.0)
	if finger.name == "Thumb":
		c *= THUMB_CURL_SCALE
	var seg := FINGER_LEN * arm_scale / float(FINGER_SEGMENTS)
	var ang := 0.0
	var local := Vector3.ZERO
	for i in FINGER_SEGMENTS:
		ang += c * float(FINGER_CURL_MAX[i])
		local.z += seg * cos(ang)
		local.y -= seg * sin(ang)
	return finger.global_transform * local


## Is a world point inside this body, judged from its collision shape?
func _point_in_body(body: Node3D, p: Vector3) -> bool:
	for ch in body.get_children():
		var cs := ch as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var local := cs.global_transform.affine_inverse() * p
		var sh := cs.shape
		if sh is BoxShape3D:
			var h: Vector3 = (sh as BoxShape3D).size * 0.5 + Vector3.ONE * CONTACT_MARGIN
			if absf(local.x) < h.x and absf(local.y) < h.y and absf(local.z) < h.z:
				return true
		elif sh is SphereShape3D:
			if local.length() < (sh as SphereShape3D).radius + CONTACT_MARGIN:
				return true
		elif sh is CapsuleShape3D:
			var cap := sh as CapsuleShape3D
			var half_h: float = maxf(cap.height * 0.5 - cap.radius, 0.0)
			var flat := Vector3(local.x, clampf(local.y, -half_h, half_h), local.z)
			if local.distance_to(Vector3(0.0, flat.y, 0.0)) < cap.radius + CONTACT_MARGIN:
				return true
	return false


## How far the fingers close around a given object: they stop when
## they reach it, so a big crate leaves them open and a small thing
## lets them close right up (STO-CHARACTER-059).
func _grip_curl_for(body: Node) -> float:
	var r := _object_radius(body)
	return clampf(1.0 - r / GRIP_OPEN_RADIUS, GRIP_MIN_CURL, 1.0)


## Rough half-size of a body, from its collision shape where possible.
func _object_radius(body: Node) -> float:
	var node := body as Node3D
	if node == null:
		return 0.2
	for c in node.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var sh := cs.shape
		if sh is BoxShape3D:
			return (sh as BoxShape3D).size.length() * 0.5 * _node_scale(node)
		if sh is SphereShape3D:
			return (sh as SphereShape3D).radius * _node_scale(node)
		if sh is CapsuleShape3D:
			return (sh as CapsuleShape3D).radius * _node_scale(node)
	return 0.2


func _node_scale(node: Node3D) -> float:
	var sc := node.global_transform.basis.get_scale()
	return maxf(sc.x, maxf(sc.y, sc.z))


func _update_visual(arm: Dictionary) -> void:
	var pts: PackedVector3Array = arm["points"]
	var root: Node3D = arm["root"]
	# While holding something, roll the HAND so its palm faces what it
	# is holding — otherwise the fingers curl away from it.
	var palm := Vector3.INF
	var held = arm["grabbed_body"]
	if bool(arm["grabbed"]) and held != null and is_instance_valid(held):
		palm = (held as Node3D).global_position
	for s in range(PART_NAMES.size()):
		var part := root.get_node(PART_NAMES[s]) as Node3D
		var toward := palm if String(PART_NAMES[s]) == "Hand" else Vector3.INF
		_orient_between(part, pts[s], pts[s + 1], toward)


## Place a part so its origin sits at `a` and its local +Z axis points
## toward `b` (meshes are modelled along +Z).
##
## `palm_toward` rolls the part so its local -Y faces that point. The
## hand needs it: a quaternion that only aims +Z leaves the roll
## arbitrary, so the PALM could face any direction — including away
## from the thing being held, with the fingers curling into empty air.
## Everything else has no front, so it does not care.
func _orient_between(part: Node3D, a: Vector3, b: Vector3,
		palm_toward := Vector3.INF) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 1e-5:
		part.global_position = a
		return
	var fwd := dir / len
	var basis := Basis(Quaternion(Vector3(0, 0, 1), fwd))
	if palm_toward.is_finite():
		# Roll so -Y points at the target, keeping +Z along the arm.
		var want := palm_toward - a
		want = want - fwd * want.dot(fwd)       # flatten onto the palm plane
		if want.length() > 1e-4:
			var down := want.normalized()
			var right := down.cross(fwd).normalized()
			basis = Basis(right, -down, fwd)
	part.global_transform = Transform3D(basis, a)


# ---------------------------------------------------------------------
# Grab input & aiming — STO-CHARACTER-003
# ---------------------------------------------------------------------

func _update_grab_input() -> void:
	if _camera == null:
		return
	# E toggles grab-mode / punch-mode (STO-CHARACTER-007).
	if Input.is_action_just_pressed("toggle_arm_mode"):
		# CYCLE, not flip: there are three modes now, and flipping a
		# bool could only ever reach two of them (STO-CHARACTER-069).
		toggle_mode()

	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	for i in range(_arms.size()):
		var arm: Dictionary = _arms[i]
		var pressed := captured and Input.is_mouse_button_pressed(int(arm["button"]))
		var was_pressed: bool = arm["was_pressed"]
		if _punch_mode:
			# No grabbing while punching. HOLD the button to stick the fist
			# straight out (the ram pose); ram damage is applied elsewhere.
			arm["extended"] = pressed or bool(arm["force_extend"])
		else:
			# Edge-triggered: grab on press, release on release. Idle frames
			# leave the grab state untouched (so a programmatic grab() holds).
			if pressed and not was_pressed:
				var hit := _aim_ray()
				if not hit.is_empty():
					arm["grabbed"] = true
					arm["target"] = hit["position"]
					_attach(arm, hit.get("collider"))
			elif was_pressed and not pressed:
				_let_go(arm)
		arm["was_pressed"] = pressed


## Latch this arm onto whatever the aim ray hit (STO-CHARACTER-044).
##   - an ENEMY  -> it goes limp instantly and is hauled along by the
##                  arm (we hold a part of its ragdoll)
##   - a RIGID body (crate) -> reeled toward the hand as before
##   - anything SOLID (wall, pillar, floor) -> the anchor pulls the
##                  PLAYER toward it: a real grapple
func _attach(arm: Dictionary, col) -> void:
	arm["grabbed_body"] = null
	arm["grabbed_enemy"] = null
	if col == null:
		return
	if col == _plate:
		# Never grab your OWN piston (STO-CHARACTER-074). Making the
		# plate solid put a body directly in front of the player, so
		# every grab aimed forward latched onto it instead of onto
		# whatever was beyond.
		return
	if col.has_method("ragdoll_now"):
		var rag: Node3D = col.call("ragdoll_now")
		if rag != null:
			# Hold the torso — grabbing a limp body by the middle.
			# Torso and Pelvis are HUMANOID part names; a spider ragdoll
			# has neither, so grabbing one used to hand back null and
			# leave the arm holding nothing while thinking it held an
			# enemy. Fall through to whatever that creature's core part
			# is actually called.
			var part: RigidBody3D = rag.call("part", "Torso")
			for fallback in ["Pelvis", "Block"]:
				if part == null:
					part = rag.call("part", fallback)
			arm["grabbed_body"] = part
			arm["grabbed_enemy"] = col
			return
	if col is RigidBody3D:
		arm["grabbed_body"] = col


func _let_go(arm: Dictionary) -> void:
	var e = arm.get("grabbed_enemy")
	if e != null and is_instance_valid(e) and e.has_method("release_ragdoll"):
		e.call("release_ragdoll")
	arm["grabbed"] = false
	arm["grabbed_body"] = null
	arm["grabbed_enemy"] = null


## Ray from the centre of the screen (crosshair). Returns the raw hit
## dictionary (with "position" and "collider"), or an empty dict.
func _aim_ray() -> Dictionary:
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * GRAB_REACH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var skip: Array = []
	if _player != null:
		skip.append(_player.get_rid())
	# Skip our OWN piston plate (STO-CHARACTER-074). It is a solid body
	# held directly in front of the player, so an aim ray hit it every
	# single time and nothing beyond it could ever be grabbed — the
	# player kept grabbing their own piston.
	var pb := _plate as CollisionObject3D
	if pb != null:
		skip.append(pb.get_rid())
	query.exclude = skip
	return get_world_3d().direct_space_state.intersect_ray(query)


# ---------------------------------------------------------------------
# Helpers / test API
# ---------------------------------------------------------------------

func _shoulder_world(side: int) -> Vector3:
	var local := Vector3(shoulder_offset.x * side, shoulder_offset.y, shoulder_offset.z)
	return global_transform * local


func _is_authority() -> bool:
	return _player != null and _player.is_multiplayer_authority()

## --- Accessors used by the headless smoke tests ---

func arm_count() -> int:
	return _arms.size()

func shoulder_point(i: int) -> Vector3:
	var pts: PackedVector3Array = _arms[i]["points"]
	return pts[0]

func hand_point(i: int) -> Vector3:
	var pts: PackedVector3Array = _arms[i]["points"]
	return pts[pts.size() - 1]

## Worst-case ratio of a segment's actual length to its rest length.
## ~1.0 means the arm is solid (segments never pull apart); >1 means it
## is stretching into gaps.
func max_segment_stretch(i: int) -> float:
	var pts: PackedVector3Array = _arms[i]["points"]
	var lengths: Array = _arms[i]["lengths"]
	var worst := 1.0
	for s in range(lengths.size()):
		var rest := float(lengths[s])
		if rest > 0.0:
			worst = maxf(worst, pts[s].distance_to(pts[s + 1]) / rest)
	return worst

func total_length(i: int) -> float:
	var sum := 0.0
	var lengths: Array = _arms[i]["lengths"]
	for l in lengths:
		sum += float(l)
	return sum

# ---------------------------------------------------------------------
# Punch mode — STO-CHARACTER-007 / 008 / 009
# ---------------------------------------------------------------------

## Kept so older callers and tests still work; goes through set_mode.
func set_punch_mode(on: bool) -> void:
	set_mode(MODE_PUNCH if on else MODE_GRAB)


## Make the switch noticeable (but not loud): the fists take on a warm
## glow in punch mode, back to plain metal in grab mode.
func _update_fist_look() -> void:
	if _fist_mat == null:
		return
	if _mode == MODE_PISTON:
		# Cold blue-white: the arms are one shaft, not two fists.
		_fist_mat.albedo_color = Color(0.55, 0.68, 0.85)
		_fist_mat.emission_enabled = true
		_fist_mat.emission = Color(0.4, 0.7, 1.0)
		_fist_mat.emission_energy_multiplier = 0.8
	elif _punch_mode:
		_fist_mat.albedo_color = Color(0.8, 0.42, 0.32)
		_fist_mat.emission_enabled = true
		_fist_mat.emission = Color(0.95, 0.4, 0.2)
		_fist_mat.emission_energy_multiplier = 0.7
	else:
		_fist_mat.albedo_color = Color(0.62, 0.64, 0.68)
		_fist_mat.emission_enabled = false


## THREE modes now, cycled by E (STO-CHARACTER-069):
##   GRAB -> PUNCH -> PISTON -> GRAB
##
## The piston used to be a separate F toggle sitting ON TOP of grab
## mode, so the arms were somehow gripping and pistoning at once. It is
## a proper mode: while it is on, the arms neither grab nor punch.
## How firmly the hands are drawn together in piston mode, and how far
## in front of the chest they meet.
## How quickly the hands come together. Eased through _piston_blend
## rather than applied flat, so the arms visibly FOLD into the piston
## over about half a second instead of snapping to it in three frames
## (STO-CHARACTER-073).
const PISTON_JOIN_LERP := 0.30
const PISTON_BLEND_RATE := 2.2
## Held OUT, not resting (STO-CHARACTER-073): far enough forward that
## the arms are extended whenever the mode is on, not only mid-stroke.
const PISTON_JOIN_DIST := 1.45
## Firing (STO-CHARACTER-072): the ARMS are the piston. They drive
## outward from the chest and their joined hands are the head — there
## is no separate object, so the reach is honestly limited by how long
## the arms are.
const PISTON_MAX_EXTEND := 1.7      # past the joined-hands rest point
const PISTON_FULL_SPEED := 9.375    # 1.25x the Runner's pounce
const PISTON_MIN_SPEED := 3.0
const PISTON_RETRACT := 7.0
const PISTON_HIT_RADIUS := 1.0
const PISTON_LAUNCH := 24.0
var _piston_extend := 0.0
var _piston_speed := PISTON_FULL_SPEED
var _piston_out := false
var _piston_hit: Dictionary = {}
## 0 = arms apart and normal, 1 = fully locked into the piston.
var _piston_blend := 0.0
## The flat plate carried on the front of the joined hands
## (STO-CHARACTER-073): a small shield, not a fist.
## Bigger and chunkier so it reads as a heavy slab of machinery.
const PLATE_W := 0.95
const PLATE_H := 0.80
const PLATE_T := 0.20
## HOW HEAVY IT FEELS (STO-CHARACTER-073). The piston does not follow
## your view instantly — it lags and catches up, so swinging round
## drags the machine after you. This one number is most of what
## separates a heavy machine from a pose.
const PISTON_TURN_LAG := 3.0
var _plate: Node3D
## The direction the piston is actually pointing, which chases the
## camera rather than matching it.
var _piston_aim := Vector3.FORWARD
const MODE_GRAB := 0
const MODE_PUNCH := 1
const MODE_PISTON := 2
var _mode := MODE_GRAB


## Where both hands meet to form the shaft: dead centre, in front of
## the player, at the height the piston fires from.
func _piston_point() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var mid := (_shoulder_world(-1) + _shoulder_world(1)) * 0.5
	# _piston_aim, NOT aim_dir(): the machine swings after your view.
	return mid + _piston_aim * (PISTON_JOIN_DIST + _piston_extend)


## E cycles GRAB <-> PUNCH only (STO-CHARACTER-073). The piston has
## its own key, F, because it is a bigger change of state than a fist
## and having to tab past it to get back to grabbing was clumsy.
func toggle_mode() -> void:
	set_mode(MODE_GRAB if _mode != MODE_GRAB else MODE_PUNCH)


## F: into the piston from wherever you are, and back out to GRAB.
func toggle_piston_mode() -> bool:
	set_mode(MODE_GRAB if _mode == MODE_PISTON else MODE_PISTON)
	return _mode == MODE_PISTON


func set_mode(m: int) -> void:
	_mode = clampi(m, MODE_GRAB, MODE_PISTON)
	# Nothing may stay held through a mode change.
	for i in range(_arms.size()):
		_let_go(_arms[i])
	_punch_mode = _mode == MODE_PUNCH
	_piston_extend = 0.0
	_piston_out = false
	_update_fist_look()
	print("[ARMS] mode = %s" % ["GRAB", "PUNCH", "PISTON"][_mode])


## Drive the arms out as one piston. `charge01` sets the SPEED.
func fire_piston(charge01: float) -> bool:
	if _mode != MODE_PISTON or _piston_out or _piston_extend > 0.01:
		return false
	_piston_speed = lerpf(PISTON_MIN_SPEED, PISTON_FULL_SPEED,
			clampf(charge01, 0.0, 1.0))
	_piston_out = true
	_piston_hit.clear()
	return true


## How far the arms are currently driven out.
func piston_extend() -> float:
	return _piston_extend


## How far through folding into the piston the arms are, 0 to 1.
func piston_blend() -> float:
	return _piston_blend


func piston_firing() -> bool:
	return _piston_out or _piston_extend > 0.01


## Step the piston stroke, and launch whatever the joined hands reach.
func _update_piston_stroke(delta: float) -> void:
	if _piston_out:
		_piston_extend += _piston_speed * delta
		if _piston_extend >= PISTON_MAX_EXTEND:
			_piston_extend = PISTON_MAX_EXTEND
			_piston_out = false
	elif _piston_extend > 0.0:
		_piston_extend = maxf(_piston_extend - PISTON_RETRACT * delta, 0.0)
		return                                   # only the drive hits
	else:
		return
	# The joined HANDS are the head of the piston.
	var head := _piston_point()
	var dir := _piston_aim
	for group in ["enemies", "players"]:
		for n in get_tree().get_nodes_in_group(group):
			var node := n as Node3D
			if node == null or node == _player:
				continue
			if head.distance_to(node.global_position) > PISTON_HIT_RADIUS:
				continue
			var id := node.get_instance_id()
			if _piston_hit.has(id):
				continue
			_piston_hit[id] = true
			var push := dir * PISTON_LAUNCH + Vector3.UP * 4.0
			if group == "players":
				if node.has_method("launch_by_piston"):
					node.call("launch_by_piston", push)
			elif node.has_method("apply_knockback"):
				node.call("apply_knockback", push * 3.0)


## Carry the plate on the joined hands, facing the way you aim.
func _update_plate() -> void:
	if _plate == null:
		return
	_plate.visible = _piston_blend > 0.05
	# Only solid while you can see it — an invisible plate parked in
	# front of the player would be a wall nobody could explain.
	_plate.set_collision_layer(1 if _plate.visible else 0)
	_plate.set_collision_mask(1 if _plate.visible else 0)
	if not _plate.visible:
		return
	var at := _piston_point()
	var fwd := _piston_aim
	var up := Vector3.UP
	if absf(fwd.dot(up)) > 0.98:
		up = Vector3.FORWARD               # looking straight up or down
	var right := up.cross(fwd).normalized()
	var real_up := fwd.cross(right).normalized()
	# Scale folded INTO the basis, not assigned afterwards. Setting
	# .scale on a top_level node rebuilt its transform and dumped the
	# plate at the world origin — 40 m from the player, which is why it
	# was invisible in game while every test said "visible = true".
	var grow: float = maxf(_piston_blend, 0.05)
	_plate.global_transform = Transform3D(
			Basis(right * grow, real_up * grow, fwd * grow), at)


## How far the piston is currently lagging behind your view, in
## radians — 0 when it has caught up.
func piston_turn_lag() -> float:
	return _piston_aim.angle_to(aim_dir().normalized())


func plate_visible() -> bool:
	return _plate != null and _plate.visible


func arm_mode() -> int:
	return _mode


func is_piston_mode() -> bool:
	return _mode == MODE_PISTON


func is_punch_mode() -> bool:
	return _punch_mode


func shockwaves_spawned() -> int:
	return _shockwaves


## Force a hand's extended (stuck-out) state — for tests / scripting.
func set_extended(i: int, on: bool) -> void:
	_arms[i]["extended"] = on
	_arms[i]["force_extend"] = on


func is_extended(i: int) -> bool:
	return bool(_arms[i]["extended"])


## Where a fist reaches when stuck straight out (the ram pose): forward
## from the shoulder, out to (roughly) the arm's length.
func _reach_point(side: int) -> Vector3:
	var shoulder := _shoulder_world(side)
	# Punch where you LOOK, including up and down (STO-CHARACTER-046).
	# This used to take the player body's facing and flatten it
	# (fwd.y = 0), but pitch lives on the camera, not the body — so
	# every punch came out dead horizontal no matter where you aimed.
	return shoulder + aim_dir() * (UPPER_LEN + FORE_LEN + HAND_LEN) * arm_scale


## The direction the player is aiming, pitch included.
func aim_dir() -> Vector3:
	if _camera != null:
		return -_camera.global_transform.basis.z
	if _player != null:
		return -_player.global_transform.basis.z
	return Vector3.FORWARD


## An extended fist that touches an enemy while the player has momentum
## deals damage scaled by that momentum; a fast enough ram makes a
## shockwave. (STO-CHARACTER-021)
func _ram_damage(delta: float) -> void:
	for key in _ram_cd.keys():
		_ram_cd[key] = float(_ram_cd[key]) - delta
	if _player == null:
		return
	var vel: Vector3 = _player.velocity
	var speed := vel.length()
	if speed < RAM_MIN_SPEED:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var dir := vel / speed
	for i in range(_arms.size()):
		if not _arms[i]["extended"]:
			continue
		var fist := hand_point(i)
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var node := e as Node3D
			var eid := node.get_instance_id()
			if float(_ram_cd.get(eid, 0.0)) > 0.0:
				continue
			var center := node.global_position + Vector3(0.0, 0.8, 0.0)
			if fist.distance_to(center) < RAM_HIT_RADIUS:
				if _player != null and _player.has_method("deal_damage"):
					_player.deal_damage(node, speed * RAM_DAMAGE_SCALE)
				elif node.has_method("take_damage"):
					node.call("take_damage", speed * RAM_DAMAGE_SCALE)
				Sounds.make(center, Sounds.PUNCH)
				if node.has_method("apply_knockback"):
					# Knock them where the punch is AIMED (so an upward
					# punch launches them), with the lift folded in;
					# momentum still sets how hard.
					var punch_dir := (aim_dir() + Vector3.UP * RAM_KNOCKBACK_LIFT) \
							.normalized()
					node.call("apply_knockback", punch_dir
							* (RAM_KNOCKBACK_BASE + speed * RAM_KNOCKBACK),
							center)   # where the fist landed
				if speed >= RAM_SHOCKWAVE_SPEED:
					_spawn_shockwave(center, speed)
				_ram_cd[eid] = RAM_COOLDOWN


func _spawn_shockwave(at: Vector3, power: float) -> void:
	var sw: Node3D = ShockwaveScript.new()
	sw.power = power
	sw.set("source", _player)
	# Parent under the players' container (at world origin) and place it.
	var host: Node = self
	if _player != null and _player.get_parent() != null:
		host = _player.get_parent()
	sw.position = at
	host.add_child(sw)
	_shockwaves += 1


func grab(i: int, target: Vector3) -> void:
	_arms[i]["grabbed"] = true
	_arms[i]["grabbed_body"] = null
	_arms[i]["target"] = target

## Programmatic equivalent of an aim-grab: latches onto `collider`
## exactly as a mouse press would, so enemies ragdoll and solid
## anchors reel the player in. (Tests, and any ability that grabs.)
func grab_target(i: int, collider, point: Vector3) -> void:
	_arms[i]["grabbed"] = true
	_arms[i]["target"] = point
	_attach(_arms[i], collider)


func grabbed_enemy(i: int) -> Node:
	return _arms[i].get("grabbed_enemy")


func grabbed_body(i: int) -> Node:
	return _arms[i].get("grabbed_body")


func grab_body(i: int, body: Node, point: Vector3) -> void:
	if body == _plate:
		return              # never your own piston (STO-CHARACTER-074)
	_arms[i]["grabbed"] = true
	_arms[i]["grabbed_body"] = body
	_arms[i]["target"] = point

func release(i: int) -> void:
	_let_go(_arms[i])   # also lets a held enemy go limp-and-recover

func is_grabbed(i: int) -> bool:
	return bool(_arms[i]["grabbed"])
