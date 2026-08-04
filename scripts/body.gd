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
# Procedural foot placement (world-space plant positions).
var _feet_init := false
var _foot_pos: Array = [Vector3.ZERO, Vector3.ZERO]
var _foot_from: Array = [Vector3.ZERO, Vector3.ZERO]
var _foot_to: Array = [Vector3.ZERO, Vector3.ZERO]
var _stepping: Array = [false, false]
var _step_t: Array = [0.0, 0.0]


func _ready() -> void:
	_player = get_parent()
	_is_local = _player != null and _player.is_multiplayer_authority()
	if _player != null:
		_prev_pos = _player.global_position
	_body_mat = _make_material()
	_build()
	set_process(true)
	print("[BODY] built humanoid with %d joints%s%s"
			% [joint_count(),
			" (fade shader)" if _is_local else "",
			"" if build_human_arms else " (no human arms)"])


func _make_material() -> Material:
	if _is_local:
		var sh := Shader.new()
		sh.code = FADE_SHADER
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("base_color", Vector3(GRAY.r, GRAY.g, GRAY.b))
		sm.set_shader_parameter("fade_near", FADE_NEAR)
		sm.set_shader_parameter("fade_far", FADE_FAR)
		return sm
	var m := StandardMaterial3D.new()
	m.albedo_color = GRAY
	m.roughness = 0.75
	return m


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


func _build() -> void:
	# Spine
	_pelvis = _joint(self, "Pelvis", Vector3(0.0, _base_pelvis_y, 0.0))
	_seg(_pelvis, Vector3(0.34, 0.22, 0.22), Vector3.ZERO)
	var torso := _joint(_pelvis, "Torso", Vector3(0.0, 0.28, 0.0))
	_seg(torso, Vector3(0.40, 0.44, 0.24), Vector3(0.0, 0.06, 0.0))
	var neck := _joint(torso, "Neck", Vector3(0.0, 0.30, 0.0))
	_seg(neck, Vector3(0.10, 0.12, 0.10), Vector3.ZERO)
	var head := _joint(neck, "Head", Vector3(0.0, 0.16, 0.0))
	_seg(head, Vector3(0.26, 0.30, 0.26), Vector3.ZERO)

	for side_v in [-1.0, 1.0]:
		var side := float(side_v)
		var s := "L" if side < 0.0 else "R"

		# Shoulder nub always exists (the mechanical arms attach here).
		var shoulder := _joint(torso, "Shoulder" + s, Vector3(0.26 * side, 0.18, 0.0))
		_seg(shoulder, Vector3(0.15, 0.15, 0.15), Vector3.ZERO)
		if build_human_arms:
			var upper := _joint(shoulder, "UpperArm" + s, Vector3.ZERO)
			_seg(upper, Vector3(0.11, 0.32, 0.11), Vector3(0.0, -0.16, 0.0))
			var fore := _joint(upper, "Forearm" + s, Vector3(0.0, -0.32, 0.0))
			_seg(fore, Vector3(0.10, 0.30, 0.10), Vector3(0.0, -0.15, 0.0))
			var hand := _joint(fore, "Hand" + s, Vector3(0.0, -0.30, 0.0))
			_seg(hand, Vector3(0.12, 0.14, 0.12), Vector3.ZERO)
			_uppers.append(upper)

		# Legs
		var hip := _joint(_pelvis, "Hip" + s, Vector3(0.12 * side, -0.08, 0.0))
		var thigh := _joint(hip, "Thigh" + s, Vector3.ZERO)
		_seg(thigh, Vector3(0.15, 0.42, 0.15), Vector3(0.0, -0.21, 0.0))
		var shin := _joint(thigh, "Shin" + s, Vector3(0.0, -0.42, 0.0))
		_seg(shin, Vector3(0.13, 0.42, 0.13), Vector3(0.0, -0.21, 0.0))
		var foot := _joint(shin, "Foot" + s, Vector3(0.0, -0.42, 0.0))
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

	for k in _hips.size():
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
		var dir := -1.0 if k == 0 else 1.0
		var upper: Node3D = _uppers[k]
		upper.rotation.x = sw * dir * amp * 0.9


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
	var dd := clampf(real_d, 0.05, THIGH_LEN + SHIN_LEN - 0.02)
	var a := (THIGH_LEN * THIGH_LEN - SHIN_LEN * SHIN_LEN + dd * dd) / (2.0 * dd)
	var h := sqrt(maxf(0.0, THIGH_LEN * THIGH_LEN - a * a))
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
