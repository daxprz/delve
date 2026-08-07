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
const UPPER_LEN := 0.90
const UPPER_TH := 0.28
const FORE_LEN := 0.78
const FORE_TH := 0.22
const HAND_LEN := 0.34   # wrist -> fingertip
const FIST_TH := 0.40    # fists are chunky

# --- Verlet ragdoll tuning ---
const GRAVITY := Vector3(0.0, -12.0, 0.0)
const DAMPING := 0.96        # 1.0 = frictionless, lower = heavier/draggier
const SOLVER_ITERATIONS := 16  # more = stiffer segments that never pull apart
const FLOOR_Y := 0.06        # ground plane top (main.tscn ground at y=0)
const CHAIN_MARGIN := 0.06   # how far a chain link is kept off a surface it hits
## How fast a grabbing hand reaches its target. Low = heavy (eases over
## several frames) instead of snapping there instantly.
const GRAB_REACH_LERP := 0.18

# --- Grab tuning ---
const GRAB_REACH := 3.0        # how far a hand can reach to grab (short reach)
const REEL_IMPULSE := 0.5      # how strongly a grabbed box is pulled to the hand

# --- Ram tuning (STO-CHARACTER-021) ---
# In punch mode you hold the button to stick the fist STRAIGHT OUT; running
# an extended fist into an enemy deals damage scaled by your momentum.
const ShockwaveScript := preload("res://scripts/shockwave.gd")
const RAM_MIN_SPEED := 3.0          # need at least this much speed to hurt
const RAM_DAMAGE_SCALE := 2.2       # enemy damage per m/s of momentum
const RAM_HIT_RADIUS := 0.9         # how close the fist must get
const RAM_KNOCKBACK := 0.35         # knockback per m/s of momentum
const RAM_SHOCKWAVE_SPEED := 9.0    # momentum needed for a shockwave on a ram hit
const RAM_COOLDOWN := 0.4           # per-enemy, so one ram = ~one hit

var _ram_cd: Dictionary = {}
## In punch mode the fists are held out in a ready guard in front of the
## player (STO-CHARACTER-007), instead of dangling.
const GUARD_FORWARD := 0.8         # how far in front the fists are held
const GUARD_HEIGHT := 0.05         # slightly above the shoulder
const GUARD_LERP := 0.16           # how firmly they hold the guard

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

	print("[ARMS] built 2 procedural ragdoll arms, 3 parts each "
			+ "(upper arm + forearm + fist), scale %.2f" % arm_scale)


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
		"side": side, "button": button, "root": root,
		"points": pts, "prev": pts.duplicate(), "lengths": lengths,
		"grabbed": false, "target": Vector3.ZERO, "was_pressed": false,
		"grabbed_body": null, "extended": false, "force_extend": false,
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

	var span := FIST_TH * 0.7 * arm_scale
	for i in 4:
		var knuckle := MeshInstance3D.new()
		knuckle.name = "Knuckle%d" % i
		var kbox := BoxMesh.new()
		kbox.size = Vector3(FIST_TH * 0.2, FIST_TH * 0.22, HAND_LEN * 0.5) * arm_scale
		knuckle.mesh = kbox
		knuckle.material_override = _metal
		var t := float(i) / 3.0
		knuckle.position = Vector3(
				lerpf(-span * 0.5, span * 0.5, t),
				FIST_TH * 0.45 * arm_scale,
				HAND_LEN * 0.7 * arm_scale)
		hand.add_child(knuckle)
	return hand


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

	for arm_v in _arms:
		var arm: Dictionary = arm_v
		_simulate_arm(arm, delta)
		_apply_grab_pull(arm)
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
		pts[last] += (target - pts[last]) * GRAB_REACH_LERP
	elif _punch_mode:
		# Punch mode: hold the fist in a ready guard, or — if the button is
		# held — STICK IT STRAIGHT OUT in front (the ram pose).
		var target := _guard_point(int(arm["side"]))
		if arm["extended"]:
			target = _reach_point(int(arm["side"]))
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
	if body != null and is_instance_valid(body) and body is RigidBody3D:
		# Grabbed a movable body (the box): reel it toward the hand, and
		# keep the visual hand stuck to it.
		var bpos: Vector3 = body.global_position
		arm["target"] = bpos
		var to_hand := shoulder - bpos
		if to_hand.length() > 0.6:
			body.apply_central_impulse(to_hand.normalized() * REEL_IMPULSE)
		return

	# Grabbed something solid (wall/pillar): the hand simply holds onto the
	# point — no rope, no swing. Grabbing is just grabbing now.


func _update_visual(arm: Dictionary) -> void:
	var pts: PackedVector3Array = arm["points"]
	var root: Node3D = arm["root"]
	for s in range(PART_NAMES.size()):
		var part := root.get_node(PART_NAMES[s]) as Node3D
		_orient_between(part, pts[s], pts[s + 1])


## Place a part so its origin sits at `a` and its local +Z axis points
## toward `b` (meshes are modelled along +Z).
func _orient_between(part: Node3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 1e-5:
		part.global_position = a
		return
	var basis := Basis(Quaternion(Vector3(0, 0, 1), dir / len))
	part.global_transform = Transform3D(basis, a)


# ---------------------------------------------------------------------
# Grab input & aiming — STO-CHARACTER-003
# ---------------------------------------------------------------------

func _update_grab_input() -> void:
	if _camera == null:
		return
	# E toggles grab-mode / punch-mode (STO-CHARACTER-007).
	if Input.is_action_just_pressed("toggle_arm_mode"):
		set_punch_mode(not _punch_mode)

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
					var col = hit.get("collider")
					if col is RigidBody3D:
						arm["grabbed_body"] = col
					else:
						# A solid surface (wall/pillar): the hand just latches
						# onto the point — no rope swing (grab-only).
						arm["grabbed_body"] = null
			elif was_pressed and not pressed:
				arm["grabbed"] = false
				arm["grabbed_body"] = null
		arm["was_pressed"] = pressed


## Ray from the centre of the screen (crosshair). Returns the raw hit
## dictionary (with "position" and "collider"), or an empty dict.
func _aim_ray() -> Dictionary:
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * GRAB_REACH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	if _player != null:
		query.exclude = [_player.get_rid()]
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

func set_punch_mode(on: bool) -> void:
	_punch_mode = on
	if on:
		# You can't hold a grab while punching — let go of everything.
		for i in range(_arms.size()):
			_arms[i]["grabbed"] = false
			_arms[i]["grabbed_body"] = null
	_update_fist_look()
	print("[ARMS] mode = %s" % ("PUNCH" if on else "GRAB"))


## Make the switch noticeable (but not loud): the fists take on a warm
## glow in punch mode, back to plain metal in grab mode.
func _update_fist_look() -> void:
	if _fist_mat == null:
		return
	if _punch_mode:
		_fist_mat.albedo_color = Color(0.8, 0.42, 0.32)
		_fist_mat.emission_enabled = true
		_fist_mat.emission = Color(0.95, 0.4, 0.2)
		_fist_mat.emission_energy_multiplier = 0.7
	else:
		_fist_mat.albedo_color = Color(0.62, 0.64, 0.68)
		_fist_mat.emission_enabled = false


## Where a fist is held in punch mode: out in front of its shoulder.
func _guard_point(side: int) -> Vector3:
	var shoulder := _shoulder_world(side)
	var fwd := Vector3.FORWARD
	if _player != null:
		fwd = -_player.global_transform.basis.z
	return shoulder + fwd * GUARD_FORWARD + Vector3.UP * GUARD_HEIGHT


func toggle_mode() -> void:
	set_punch_mode(not _punch_mode)


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
	var fwd := Vector3.FORWARD
	if _player != null:
		fwd = -_player.global_transform.basis.z
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	return shoulder + fwd * (UPPER_LEN + FORE_LEN + HAND_LEN) * arm_scale


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
				if node.has_method("apply_knockback"):
					node.call("apply_knockback", dir * speed * RAM_KNOCKBACK)
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

func grab_body(i: int, body: Node, point: Vector3) -> void:
	_arms[i]["grabbed"] = true
	_arms[i]["grabbed_body"] = body
	_arms[i]["target"] = point

func release(i: int) -> void:
	_arms[i]["grabbed"] = false
	_arms[i]["grabbed_body"] = null

func is_grabbed(i: int) -> bool:
	return bool(_arms[i]["grabbed"])
