class_name Body
extends Node3D
## A procedural jointed humanoid body (STO-CHARACTER-012) with
## procedurally-generated animation (STO-CHARACTER-016): the legs and
## arms swing based on how fast the player is moving — no keyframed
## animation, it's all computed from the walk phase.
##
## Fade (STO-CHARACTER-014): a distance-fade shader makes near parts
## vanish for the owner's close camera but stay solid in the mirror.
##
## Grabber: `build_human_arms = false` -> no human arms are built (the
## mechanical arms attach at the shoulders instead).

const GRAY := Color(0.6, 0.6, 0.6)
const FADE_NEAR := 0.5
const FADE_FAR := 1.0

# Walk animation tuning (procedural gait — STO-CHARACTER-016).
const IDLE_RATE := 1.6       # arm-swing phase speed when standing
const MAX_SWING := 0.6       # max arm swing (radians)
const THIGH_LEN := 0.42
const SHIN_LEN := 0.42
const STRIDE := 0.55         # how far ahead a foot plants
const STEP_TRIGGER := 0.35   # how far a foot lags before it takes a step
const STEP_TIME := 0.18      # seconds per step
const STEP_LIFT := 0.14      # how high the foot lifts mid-step
const FOOT_RAISE := 0.05     # lift the foot mesh so it rests on the ground
const MAX_STEP := 0.5        # a foot never strays farther than this from its hip

const FADE_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley;
uniform vec3 base_color : source_color = vec3(0.6);
uniform float fade_near = 0.5;
uniform float fade_far = 1.0;
uniform float rough = 0.75;
varying vec3 v_world;
void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float d = distance(v_world, CAMERA_POSITION_WORLD);
	ALBEDO = base_color;
	ROUGHNESS = rough;
	ALPHA = clamp((d - fade_near) / (fade_far - fade_near), 0.0, 1.0);
}
"""

## Build human arms (upper/forearm/hand)? False for the Grabber, whose
## mechanical arms attach at the shoulders instead. Set before _ready.
var build_human_arms := true

## Big ears on the head (STO-CHARACTER-038, Sniper).
var ears := false

## Base body color. Set before _ready (players: GRAY; enemies: red).
var base_color := GRAY

## Distance-fade near the camera (first-person owners). Enemies set
## this false — their bodies must stay solid up close. Set before _ready.
var use_fade := true

## Procedural variation (STO-ENEMIES-003): 0 = exact canonical
## proportions (players). Any other value seeds an RNG that varies
## limb lengths, torso, head and bulk, so no two bodies look alike.
## Use a deterministic seed (e.g. name hash) so every peer renders the
## same individual. Set before _ready.
var variation_seed := 0

# Proportion multipliers (filled from variation_seed in _ready).
var _leg_scale := 1.0
var _arm_scale := 1.0
var _torso_scale := 1.0
var _head_scale := 1.0
var _bulk := 1.0
# Effective bone lengths (canonical consts x _leg_scale).
var _thigh_len := THIGH_LEN
var _shin_len := SHIN_LEN

var _is_local := false
var _body_mat: Material
var _player

# Animation state.
var _walk_phase := 0.0
var _prev_pos := Vector3.ZERO
var _pelvis: Node3D
var _base_pelvis_y := 0.92
var _hips: Array = []     # [L, R]
var _thighs: Array = []
var _shins: Array = []
var _feet: Array = []
var _uppers: Array = []   # empty for the Grabber
var _forearms: Array = []
var _hands: Array = []
var _arm_sides: Array = []   # -1 left / +1 right, per built arm
var _torso: Node3D
var _neck: Node3D
var _head: Node3D
# Procedural foot placement (world-space plant positions).
var _feet_init := false
var _foot_pos: Array = [Vector3.ZERO, Vector3.ZERO]
var _foot_from: Array = [Vector3.ZERO, Vector3.ZERO]
var _foot_to: Array = [Vector3.ZERO, Vector3.ZERO]
var _stepping: Array = [false, false]
var _step_t: Array = [0.0, 0.0]
# One-leg buckle (STO-ENEMIES-008).
var _buckle_leg := -1
var _buckle_time := 0.0
var _buckle_total := 1.0
var _buckle_amount := 1.0


func _ready() -> void:
	_player = get_parent()
	_is_local = use_fade and _player != null and _player.is_multiplayer_authority()
	if _player != null:
		_prev_pos = _player.global_position
	if variation_seed != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = variation_seed
		_leg_scale = rng.randf_range(0.85, 1.15)
		_arm_scale = rng.randf_range(0.85, 1.2)
		_torso_scale = rng.randf_range(0.85, 1.15)
		_head_scale = rng.randf_range(0.8, 1.3)
		_bulk = rng.randf_range(0.85, 1.25)
		_thigh_len = THIGH_LEN * _leg_scale
		_shin_len = SHIN_LEN * _leg_scale
		_base_pelvis_y *= _leg_scale
	_body_mat = _make_material()
	_build()
	set_process(true)
	print("[BODY] built humanoid with %d joints%s%s%s"
			% [joint_count(),
			" (fade shader)" if _is_local else "",
			"" if build_human_arms else " (no human arms)",
			" (variation seed %d)" % variation_seed if variation_seed != 0 else ""])


func _make_material() -> Material:
	if _is_local:
		var sh := Shader.new()
		sh.code = FADE_SHADER
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("base_color",
				Vector3(base_color.r, base_color.g, base_color.b))
		sm.set_shader_parameter("fade_near", FADE_NEAR)
		sm.set_shader_parameter("fade_far", FADE_FAR)
		return sm
	var m := StandardMaterial3D.new()
	m.albedo_color = base_color
	m.roughness = 0.75
	return m


## Buckle one leg (STO-ENEMIES-008): the gait stops driving it and it
## folds/drags for `time` seconds, so a stumble reads as a real leg
## giving way rather than a whole-body lean. k: 0 = left, 1 = right.
func buckle_leg(k: int, time: float, amount := 1.0) -> void:
	_buckle_leg = clampi(k, 0, 1)
	_buckle_time = time
	_buckle_total = maxf(time, 0.001)
	_buckle_amount = amount


func is_buckling() -> bool:
	return _buckle_time > 0.0


## Retint the whole body at runtime (damage flashes, team colors).
func set_base_color(c: Color) -> void:
	if _body_mat is ShaderMaterial:
		(_body_mat as ShaderMaterial).set_shader_parameter(
				"base_color", Vector3(c.r, c.g, c.b))
	elif _body_mat is StandardMaterial3D:
		(_body_mat as StandardMaterial3D).albedo_color = c


func _joint(parent: Node3D, jname: String, offset: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = jname
	j.position = offset
	parent.add_child(j)
	return j


func _seg(joint: Node3D, size: Vector3, center: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = center
	mi.material_override = _body_mat
	joint.add_child(mi)


## One arm chain hanging from `shoulder`. `prefix` distinguishes the
## Builder's lower pair. All built arms animate with the walk.
func _build_arm(shoulder: Node3D, s: String, ar: float, prefix: String) -> void:
	# Left arms swing opposite right arms; remembered per arm so the
	# Builder's four still alternate correctly.
	_arm_sides.append(-1.0 if s == "L" else 1.0)
	var upper := _joint(shoulder, prefix + "UpperArm" + s, Vector3.ZERO)
	_seg(upper, Vector3(0.11, 0.32 * ar, 0.11), Vector3(0.0, -0.16 * ar, 0.0))
	var fore := _joint(upper, prefix + "Forearm" + s, Vector3(0.0, -0.32 * ar, 0.0))
	_seg(fore, Vector3(0.10, 0.30 * ar, 0.10), Vector3(0.0, -0.15 * ar, 0.0))
	var hand := _joint(fore, prefix + "Hand" + s, Vector3(0.0, -0.30 * ar, 0.0))
	_seg(hand, Vector3(0.12, 0.14, 0.12), Vector3.ZERO)
	_uppers.append(upper)
	_forearms.append(fore)
	_hands.append(hand)


func _build() -> void:
	# Shorthand multipliers (all 1.0 without a variation seed).
	var lg := _leg_scale
	var ar := _arm_scale
	var to := _torso_scale
	var hd := _head_scale
	var bk := _bulk

	# Spine
	_pelvis = _joint(self, "Pelvis", Vector3(0.0, _base_pelvis_y, 0.0))
	_seg(_pelvis, Vector3(0.34 * bk, 0.22, 0.22 * bk), Vector3.ZERO)
	var torso := _joint(_pelvis, "Torso", Vector3(0.0, 0.28 * to, 0.0))
	_torso = torso
	_seg(torso, Vector3(0.40 * bk, 0.44 * to, 0.24 * bk), Vector3(0.0, 0.06 * to, 0.0))
	var neck := _joint(torso, "Neck", Vector3(0.0, 0.30 * to, 0.0))
	_neck = neck
	_seg(neck, Vector3(0.10, 0.12, 0.10), Vector3.ZERO)
	var head := _joint(neck, "Head", Vector3(0.0, 0.16 * hd, 0.0))
	_head = head
	_seg(head, Vector3(0.26 * hd, 0.30 * hd, 0.26 * hd), Vector3.ZERO)

	# Big listening ears (STO-CHARACTER-038, Sniper): tall, angled
	# slightly outward so they read clearly from the side.
	if ears:
		for ear_side in [-1.0, 1.0]:
			var es := float(ear_side)
			var ear := _joint(head, "Ear" + ("L" if es < 0.0 else "R"),
					Vector3(0.13 * hd * es, 0.16 * hd, 0.0))
			ear.rotation.z = -0.28 * es
			_seg(ear, Vector3(0.07 * hd, 0.34 * hd, 0.13 * hd),
					Vector3(0.0, 0.16 * hd, 0.0))

	for side_v in [-1.0, 1.0]:
		var side := float(side_v)
		var s := "L" if side < 0.0 else "R"

		# Shoulder nub always exists (the mechanical arms attach here).
		var shoulder := _joint(torso, "Shoulder" + s,
				Vector3(0.26 * bk * side, 0.18 * to, 0.0))
		_seg(shoulder, Vector3(0.15, 0.15, 0.15), Vector3.ZERO)
		if build_human_arms:
			_build_arm(shoulder, s, ar, "")

		# Legs
		var hip := _joint(_pelvis, "Hip" + s, Vector3(0.12 * bk * side, -0.08, 0.0))
		var thigh := _joint(hip, "Thigh" + s, Vector3.ZERO)
		_seg(thigh, Vector3(0.15, _thigh_len, 0.15), Vector3(0.0, -_thigh_len / 2.0, 0.0))
		var shin := _joint(thigh, "Shin" + s, Vector3(0.0, -_thigh_len, 0.0))
		_seg(shin, Vector3(0.13, _shin_len, 0.13), Vector3(0.0, -_shin_len / 2.0, 0.0))
		var foot := _joint(shin, "Foot" + s, Vector3(0.0, -_shin_len, 0.0))
		_seg(foot, Vector3(0.14, 0.09, 0.28), Vector3(0.0, -0.04, 0.06))
		_hips.append(hip)
		_thighs.append(thigh)
		_shins.append(shin)
		_feet.append(foot)


# ---------------------------------------------------------------------
# Procedural animation (STO-CHARACTER-016)
# ---------------------------------------------------------------------

func _process(delta: float) -> void:
	if _player == null or delta <= 0.0:
		return
	var pos: Vector3 = _player.global_position
	var move := pos - _prev_pos
	_prev_pos = pos
	var vel_h := Vector3(move.x, 0.0, move.z) / delta
	var speed := vel_h.length()
	var moving := speed > 0.4

	var forward: Vector3 = -_player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var move_dir := vel_h.normalized() if moving else forward
	var ground_y := pos.y

	# Gentle up/down bob.
	_walk_phase += delta * (speed * 1.6 if moving else IDLE_RATE)
	if _pelvis != null:
		_pelvis.position.y = _base_pelvis_y + absf(sin(_walk_phase * 2.0)) \
				* (0.03 if moving else 0.008)

	# Initialise the feet under the hips on the first frame.
	if not _feet_init:
		for k in _hips.size():
			var hw: Vector3 = _hips[k].global_position
			_foot_pos[k] = Vector3(hw.x, ground_y, hw.z)
		_feet_init = true

	# Procedural gait: each foot stays planted, then steps forward when it
	# lags too far behind, lifting in an arc. Legs bend to reach (2-bone IK).
	# Flat, forward-facing foot orientation (same for both feet).
	var foot_basis := Basis.looking_at(-forward, Vector3.UP)

	# A buckling leg stops taking steps: its foot goes slack, collapsing
	# toward (and dragging behind) the hip while the other leg carries.
	if _buckle_time > 0.0:
		_buckle_time -= delta
		var bt := clampf(_buckle_time / _buckle_total, 0.0, 1.0)
		var k := _buckle_leg
		var hip_w: Vector3 = _hips[k].global_position
		var slack := hip_w + Vector3.DOWN * (_thigh_len + _shin_len) \
				* (1.0 - 0.45 * bt * _buckle_amount) \
				- move_dir * (0.35 * bt * _buckle_amount)
		slack.y = maxf(slack.y, ground_y)
		_foot_pos[k] = _foot_pos[k].lerp(slack, clampf(delta * 14.0, 0.0, 1.0))
		_stepping[k] = false
		if _buckle_time <= 0.0:
			_buckle_leg = -1

	for k in _hips.size():
		if k == _buckle_leg:
			# Slack leg: solve IK to the collapsed foot, skip stepping.
			_solve_leg(k, _hips[k].global_position, _foot_pos[k], forward)
			var bfoot: Node3D = _feet[k]
			bfoot.global_transform = Transform3D(foot_basis,
					_foot_pos[k] + Vector3.UP * FOOT_RAISE)
			continue
		var hip_world: Vector3 = _hips[k].global_position
		# When moving, aim the foot ahead of the hip AND lead it to where the
		# hip will be after the step, so fast movement doesn't leave the
		# planted foot dragging behind. When standing, aim under the hip.
		var hip_ground := Vector3(hip_world.x, ground_y, hip_world.z)
		var ahead := STRIDE * 0.5 if moving else 0.0
		var lead := vel_h * STEP_TIME
		var ideal := hip_ground + move_dir * ahead + Vector3(lead.x, 0.0, lead.z)
		ideal = _clamp_to_hip(ideal, hip_ground, MAX_STEP)
		if _stepping[k]:
			_step_t[k] = float(_step_t[k]) + delta / STEP_TIME
			var t := clampf(_step_t[k], 0.0, 1.0)
			var from_p: Vector3 = _foot_from[k]
			var to_p: Vector3 = _foot_to[k]
			var fp := from_p.lerp(to_p, t)
			fp.y += sin(t * PI) * STEP_LIFT
			_foot_pos[k] = fp
			if t >= 1.0:
				_stepping[k] = false
		else:
			var other := 1 - k
			var planted: Vector3 = _foot_pos[k]
			planted.y = ground_y  # planted foot stays on the ground
			_foot_pos[k] = planted
			# Step (even when idle) if this foot is too far from where it
			# should be and the other foot isn't mid-step.
			if planted.distance_to(ideal) > STEP_TRIGGER and not _stepping[other]:
				_stepping[k] = true
				_step_t[k] = 0.0
				_foot_from[k] = planted
				_foot_to[k] = ideal
		# Never let a leg stretch farther than MAX_STEP from its hip (so it
		# can't drag way behind — at worst the foot slides a little).
		_foot_pos[k] = _clamp_to_hip(_foot_pos[k], hip_ground, MAX_STEP)
		_solve_leg(k, hip_world, _foot_pos[k], forward)
		# Keep the foot flat on the ground, toe pointing forward.
		var foot_joint: Node3D = _feet[k]
		foot_joint.global_transform = Transform3D(foot_basis,
				_foot_pos[k] + Vector3.UP * FOOT_RAISE)

	# Arms swing opposite the legs (characters that have human arms).
	var sw := sin(_walk_phase)
	var amp := clampf(speed * 0.09, 0.05, MAX_SWING) if moving else 0.05
	for k in _uppers.size():
		var dir: float = _arm_sides[k] if k < _arm_sides.size() else 1.0
		var upper: Node3D = _uppers[k]
		# Lower arms (the Builder's second pair) swing a little behind
		# the upper pair so the four don't move as one block.
		var lag := 0.0 if k % 2 == 0 else 0.6
		upper.rotation.x = sin(_walk_phase - lag) * dir * amp * 0.9


## Clamp `p` so its horizontal distance from `center` is at most `maxd`
## (keeps p's own height).
func _clamp_to_hip(p: Vector3, center: Vector3, maxd: float) -> Vector3:
	var off := Vector3(p.x - center.x, 0.0, p.z - center.z)
	if off.length() > maxd:
		off = off.normalized() * maxd
	return Vector3(center.x + off.x, p.y, center.z + off.z)


## 2-bone IK: rotate thigh + shin so the foot reaches `foot`, knee forward.
func _solve_leg(k: int, hip: Vector3, foot: Vector3, forward: Vector3) -> void:
	var thigh: Node3D = _thighs[k]
	var shin: Node3D = _shins[k]
	var real_d := hip.distance_to(foot)
	if real_d < 0.001:
		return
	var dir := (foot - hip) / real_d
	var dd := clampf(real_d, 0.05, _thigh_len + _shin_len - 0.02)
	var a := (_thigh_len * _thigh_len - _shin_len * _shin_len + dd * dd) / (2.0 * dd)
	var h := sqrt(maxf(0.0, _thigh_len * _thigh_len - a * a))
	var bn := forward - dir * forward.dot(dir)
	bn = bn.normalized() if bn.length() > 0.001 else Vector3.FORWARD
	var knee := hip + dir * a + bn * h
	thigh.global_transform = Transform3D(_aim_basis(hip, knee, forward), hip)
	shin.global_transform = Transform3D(_aim_basis(knee, foot, forward), knee)


## Basis whose local -Y (the bone's down axis) points from `from` to `to`.
func _aim_basis(from: Vector3, to: Vector3, forward: Vector3) -> Basis:
	var down := to - from
	if down.length() < 0.001:
		return Basis()
	down = down.normalized()
	var y := -down
	var x := forward.cross(y)
	x = x.normalized() if x.length() > 0.001 else Vector3.RIGHT
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


## World position a foot is planted at (for tests).
func foot_world(k: int) -> Vector3:
	var f: Vector3 = _foot_pos[k]
	return f


## World position of a knee (the shin joint's origin).
func knee_world(k: int) -> Vector3:
	var s: Node3D = _shins[k]
	return s.global_position


## Leg bone capsules as [[a, b, radius], ...] in world space — thigh
## and shin per leg. Used by the tail to drape over the legs
## (STO-CHARACTER-034).
func leg_capsules() -> Array:
	var out: Array = []
	for k in _hips.size():
		var hip: Vector3 = _hips[k].global_position
		var knee: Vector3 = knee_world(k)
		var foot: Vector3 = _feet[k].global_position
		out.append([hip, knee, 0.11])
		out.append([knee, foot, 0.10])
	return out


## EVERY solid bone as a world-space capsule [[a, b, radius], ...]:
## torso, neck+head, both arms (upper + forearm/hand) and both legs.
## Radii come from the built segment sizes, so they follow this
## individual's procedural proportions. The tail is pushed out of all
## of them (STO-CHARACTER-035).
func body_capsules() -> Array:
	var out: Array = leg_capsules()
	if _pelvis == null:
		return out

	# Torso: pelvis up to the neck — the thickest capsule.
	if _torso != null and _neck != null:
		out.append([_pelvis.global_position, _neck.global_position,
				0.20 * _bulk])
	# Neck + head: up through the skull.
	if _neck != null and _head != null:
		var head_top: Vector3 = _head.global_position \
				+ _head.global_transform.basis.y * (0.15 * _head_scale)
		out.append([_neck.global_position, head_top, 0.15 * _head_scale])

	# Arms: shoulder -> elbow -> hand (only if human arms were built).
	for k in _uppers.size():
		var shoulder: Vector3 = (_uppers[k] as Node3D).global_position
		var elbow: Vector3 = (_forearms[k] as Node3D).global_position
		var hand: Vector3 = (_hands[k] as Node3D).global_position
		out.append([shoulder, elbow, 0.09])
		out.append([elbow, hand, 0.085])
	return out


## World position of a hip joint (for tests).
func hip_world(k: int) -> Vector3:
	var h: Node3D = _hips[k]
	return h.global_position


# ---------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------

func uses_fade_shader() -> bool:
	return _body_mat is ShaderMaterial


func thigh_swing() -> float:
	if _thighs.is_empty():
		return 0.0
	var t: Node3D = _thighs[0]
	return t.rotation.x


func joint_count() -> int:
	var arr: Array = []
	_gather(self, arr)
	return arr.size()


func _gather(n: Node, arr: Array) -> void:
	for c in n.get_children():
		if c is Node3D and not (c is MeshInstance3D):
			arr.append(c)
			_gather(c, arr)
