class_name Tail
extends Node3D
## A long procedural physics tail for the Runner (STO-CHARACTER-010).
## A Verlet chain hanging from the player's lower back: it drags and
## sways as the player moves, and wags slowly side-to-side on its own.
## Built and simulated entirely in code, like the mechanical arms.

@export var segment_count: int = 13       # long
@export var segment_length: float = 0.40
@export var base_thickness: float = 0.38   # thick / big
## Attachment point on the player: sideways, height, back (+Z = behind).
@export var base_offset: Vector3 = Vector3(0.0, 1.05, 0.45)

const GRAVITY := Vector3(0.0, -11.0, 0.0)
const DAMPING := 0.99        # a little drag so the tail lags/trails the body
const SOLVER_ITERATIONS := 10
const FLOOR_Y := 0.06
const CHAIN_MARGIN := 0.06   # how far a segment is kept off a surface it hits
const WAG_SPEED := 1.3       # radians/sec — a slow wag
const WAG_AMPLITUDE := 1.1   # how far (m) the resting tail sways sideways
## 0 => a FULLY ragdoll tail: no scripted pose or wag at all, only
## gravity + momentum + collisions drive it. It hangs/swings/drags
## purely from physics.
const BEHIND_PULL := 0.0
const REST_DOWN := 0.6
## Tail-as-weapon (STO-CHARACTER-020): a tail segment moving faster than
## TAIL_MIN_SPEED that touches an enemy deals damage scaled by its speed.
const TAIL_MIN_SPEED := 5.0
const TAIL_HIT_RADIUS := 0.75
const TAIL_DAMAGE_SCALE := 0.9
const TAIL_DAMAGE_CAP := 40.0
const TAIL_HIT_COOLDOWN := 0.35   # per-enemy, so one swing = one hit

var _hit_cd: Dictionary = {}

var _player
var _points: PackedVector3Array
var _prev: PackedVector3Array
var _parts: Array = []
var _phase := 0.0
var _mat: StandardMaterial3D


func _ready() -> void:
	_player = get_parent()
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.3, 0.55, 0.85)
	_mat.metallic = 0.2
	_mat.roughness = 0.7

	var base := _base_world()
	_points = PackedVector3Array()
	for i in segment_count + 1:
		var p := base + Vector3.DOWN * (segment_length * i)
		p.y = maxf(p.y, FLOOR_Y)  # don't start below the floor (avoids a launch)
		_points.append(p)
	_prev = _points.duplicate()  # start at rest (no velocity spike)

	for i in segment_count:
		var part := Node3D.new()
		part.name = "Seg%d" % i
		part.top_level = true
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		var t := float(i) / float(segment_count)
		var thick := lerpf(base_thickness, base_thickness * 0.2, t)  # taper to a tip
		box.size = Vector3(thick, thick, segment_length)
		seg.mesh = box
		seg.material_override = _mat
		seg.position = Vector3(0.0, 0.0, segment_length * 0.5)
		part.add_child(seg)
		add_child(part)
		_parts.append(part)

	print("[TAIL] built a %d-segment tail (%.1f m long)"
			% [segment_count, segment_count * segment_length])


func _base_world() -> Vector3:
	if _player == null:
		return global_position
	return _player.global_transform * base_offset


func _physics_process(delta: float) -> void:
	_phase += delta * WAG_SPEED
	var base := _base_world()
	var g := GRAVITY * delta * delta

	# Slow side-to-side wag, stronger toward the tip.
	var side := Vector3.RIGHT
	var back := Vector3.BACK  # +Z is behind the player
	if _player != null:
		side = _player.global_transform.basis.x
		back = _player.global_transform.basis.z
	# The resting pose: trailing behind + drooping, and slowly swaying
	# sideways (the wag is baked into the target so it survives the pull).
	var rest_dir := (back + Vector3.DOWN * REST_DOWN).normalized()
	var wag_off := side * (sin(_phase) * WAG_AMPLITUDE)

	for i in range(_points.size()):
		if i == 0:
			continue
		var frac := float(i) / float(_points.size() - 1)
		var old := _points[i]
		var moved := old + (old - _prev[i]) * DAMPING + g
		# Ease toward a resting pose that's behind the player and wagging.
		var ideal := base + rest_dir * (segment_length * i) + wag_off * frac
		moved += (ideal - moved) * BEHIND_PULL
		_points[i] = moved
		_prev[i] = old

	for _iter in SOLVER_ITERATIONS:
		_points[0] = base
		for s in range(segment_count):
			var a := s
			var b := s + 1
			var d := _points[b] - _points[a]
			var dist := d.length()
			if dist < 1e-5:
				continue
			var diff := (dist - segment_length) / dist
			if a == 0:
				_points[b] -= d * diff
			else:
				_points[a] += d * 0.5 * diff
				_points[b] -= d * 0.5 * diff
		for i in range(_points.size()):
			if _points[i].y < FLOOR_Y:
				_points[i].y = FLOOR_Y

	# A fast-swinging tail hurts enemies it hits (STO-CHARACTER-020). Done
	# BEFORE the collision resolve below, which zeroes point velocities.
	if _player != null and _player.is_multiplayer_authority():
		_hit_enemies(delta)

	# Collide with all solid geometry — including the player's body (so the
	# tail clips against the player, not through them). The first couple of
	# segments (at the attachment) still ignore the player so the base
	# doesn't fight the capsule it's stuck to.
	var space := get_world_3d().direct_space_state
	for i in range(1, _points.size()):
		if _points[i - 1].distance_to(_points[i]) < 1e-4:
			continue
		var q := PhysicsRayQueryParameters3D.create(_points[i - 1], _points[i])
		if _player != null and i < 3:
			q.exclude = [_player.get_rid()]
		var chit := space.intersect_ray(q)
		if not chit.is_empty():
			var pos: Vector3 = chit["position"]
			var nrm: Vector3 = chit["normal"]
			_points[i] = pos + nrm * CHAIN_MARGIN
			_prev[i] = _points[i]

	for s in range(segment_count):
		var part: Node3D = _parts[s]
		_orient(part, _points[s], _points[s + 1])


func _hit_enemies(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	for key in _hit_cd.keys():
		_hit_cd[key] = float(_hit_cd[key]) - delta
	# Check the outer (faster) segments against each enemy.
	for i in range(2, _points.size()):
		var vel := (_points[i] - _prev[i]) / delta
		var speed := vel.length()
		if speed < TAIL_MIN_SPEED:
			continue
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var node := e as Node3D
			var eid := node.get_instance_id()
			if float(_hit_cd.get(eid, 0.0)) > 0.0:
				continue
			if _points[i].distance_to(node.global_position + Vector3(0.0, 0.8, 0.0)) < TAIL_HIT_RADIUS:
				var dmg := minf(speed * TAIL_DAMAGE_SCALE, TAIL_DAMAGE_CAP)
				if _player != null and _player.has_method("deal_damage"):
					_player.deal_damage(node, dmg)
					_hit_cd[eid] = TAIL_HIT_COOLDOWN
				elif node.has_method("take_damage"):
					node.call("take_damage", dmg)
					_hit_cd[eid] = TAIL_HIT_COOLDOWN


func _orient(part: Node3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 1e-5:
		part.global_position = a
		return
	part.global_transform = Transform3D(Basis(Quaternion(Vector3(0, 0, 1), dir / len)), a)


# --- test accessors ---
func tail_length() -> int:
	return segment_count

func base_point() -> Vector3:
	return _points[0]

func tip_point() -> Vector3:
	return _points[_points.size() - 1]

func mid_point() -> Vector3:
	return _points[_points.size() / 2]

func is_finite_chain() -> bool:
	for p in _points:
		if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
			return false
	return true
