class_name EchoVision
extends Node3D
## Echo-sight for the blind Sniper (STO-CHARACTER-040).
##
## The Sniper's camera does not render the world at all (its cull mask
## drops the world's visual layer), so its screen is black. Instead,
## anything that MOVES emits an echo pulse: rays are cast outward from
## the mover, and wherever they strike MAP geometry a small outline
## mark is drawn. The marks fade over a moment, so the world is only
## ever briefly sketched in.
##
## Operator decisions (2026-08-07):
##   - only the WALLS around a mover are outlined, never the mover
##     itself — you learn a room's shape, not what is in it;
##   - marks are FAINTER the further they are from the Sniper, so
##     distant movement is a hint and you must close in to read it.

## Visual layer the echo marks are drawn on. The Sniper's camera sees
## ONLY this layer; every other camera ignores it.
const ECHO_LAYER := 2
## World geometry lives on physics layer 1.
const WORLD_MASK := 1

const PULSE_INTERVAL := 0.12    # min seconds between pulses per mover
const MIN_MOVE_SPEED := 0.8     # slower than this makes no sound
const RAYS_PER_PULSE := 26
const PULSE_RADIUS_BASE := 3.0  # metres, at MIN_MOVE_SPEED
const PULSE_RADIUS_PER_SPEED := 0.9
const PULSE_RADIUS_MAX := 14.0
const MARK_LIFETIME := 1.7      # seconds a mark stays before fading out
const MARK_SIZE := 0.16
const FADE_FULL := 8.0          # metres: closer than this = full strength
const FADE_NONE := 34.0         # metres: beyond this = invisible
const MAX_MARKS := 900

var _marks: Array = []          # {pos, normal, born, strength}
var _mesh: ImmediateMesh
var _mesh_node: MeshInstance3D
var _cooldowns: Dictionary = {} # instance id -> seconds until next pulse
var _last_pos: Dictionary = {}  # instance id -> last known position
var _listener: Node3D           # the Sniper (distance fade reference)
var _pulses := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_listener = get_parent() as Node3D
	_rng.seed = 20260807
	_mesh = ImmediateMesh.new()
	_mesh_node = MeshInstance3D.new()
	_mesh_node.name = "EchoMarks"
	_mesh_node.mesh = _mesh
	_mesh_node.top_level = true
	_mesh_node.layers = ECHO_LAYER
	_mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.no_depth_test = true
	_mesh_node.material_override = mat
	add_child(_mesh_node)


func _physics_process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = float(_cooldowns[key]) - delta
	_scan_movers(delta)
	_expire_marks()
	_rebuild_mesh()


## Anything that moved this tick emits an echo: enemies, players
## (including us — so the Sniper can feel out a silent room by
## walking), ragdoll parts and loose physics objects.
func _scan_movers(delta: float) -> void:
	var movers: Array = []
	movers.append_array(get_tree().get_nodes_in_group("enemies"))
	movers.append_array(get_tree().get_nodes_in_group("players"))
	movers.append_array(get_tree().get_nodes_in_group("grabbable"))

	for m in movers:
		var node := m as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var id := node.get_instance_id()
		var pos := node.global_position
		var speed := 0.0
		if _last_pos.has(id) and delta > 0.0:
			speed = (pos - _last_pos[id]).length() / delta
		_last_pos[id] = pos
		if speed < MIN_MOVE_SPEED:
			continue
		if float(_cooldowns.get(id, 0.0)) > 0.0:
			continue
		_cooldowns[id] = PULSE_INTERVAL
		emit_pulse(pos, speed, node)


## Cast rays outward from `origin`; every MAP surface they hit gets a
## mark. The mover itself, and all other creatures, are excluded — we
## only ever outline the room, never what is in it.
func emit_pulse(origin: Vector3, speed: float, source: Node3D = null) -> void:
	var radius := clampf(
			PULSE_RADIUS_BASE + speed * PULSE_RADIUS_PER_SPEED,
			PULSE_RADIUS_BASE, PULSE_RADIUS_MAX)
	var space := get_world_3d().direct_space_state
	var exclude := _creature_rids(source)
	var strength := clampf(speed / 6.0, 0.35, 1.0)
	_pulses += 1

	for i in RAYS_PER_PULSE:
		var dir := _sphere_dir(i)
		var q := PhysicsRayQueryParameters3D.create(
				origin, origin + dir * radius, WORLD_MASK)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		_marks.append({
			"pos": hit["position"],
			"normal": hit["normal"],
			"born": Time.get_ticks_msec(),
			"strength": strength,
		})
	if _marks.size() > MAX_MARKS:
		_marks = _marks.slice(_marks.size() - MAX_MARKS)


## Every creature's RID — echoes bounce off the room, not off people.
func _creature_rids(_source: Node3D) -> Array:
	var rids: Array = []
	for group in ["enemies", "players"]:
		for n in get_tree().get_nodes_in_group(group):
			if n is CollisionObject3D:
				rids.append((n as CollisionObject3D).get_rid())
	return rids


## Evenly-ish spread directions (spherical Fibonacci), jittered per
## pulse so repeated pulses fill the room in rather than re-tracing
## the same lines.
func _sphere_dir(i: int) -> Vector3:
	var k := float(i) + _rng.randf()
	var phi := acos(clampf(1.0 - 2.0 * k / float(RAYS_PER_PULSE), -1.0, 1.0))
	var theta := PI * (1.0 + sqrt(5.0)) * k
	return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))


func _expire_marks() -> void:
	var now := Time.get_ticks_msec()
	var live: Array = []
	for m in _marks:
		if now - int(m["born"]) < int(MARK_LIFETIME * 1000.0):
			live.append(m)
	_marks = live


func _rebuild_mesh() -> void:
	_mesh.clear_surfaces()
	if _marks.is_empty():
		return
	var now := Time.get_ticks_msec()
	var ear := _listener.global_position if _listener != null else global_position

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for m in _marks:
		var age := float(now - int(m["born"])) / (MARK_LIFETIME * 1000.0)
		var alpha := (1.0 - age) * float(m["strength"])
		# Fainter with distance from the Sniper (operator decision).
		var d: float = ear.distance_to(m["pos"])
		alpha *= 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL), 0.0, 1.0)
		if alpha <= 0.01:
			continue
		var col := Color(0.55, 0.85, 1.0, alpha)
		# A small cross lying ON the surface, so walls read as walls.
		var n: Vector3 = m["normal"]
		var t1 := n.cross(Vector3.UP)
		if t1.length() < 0.01:
			t1 = n.cross(Vector3.RIGHT)
		t1 = t1.normalized() * MARK_SIZE
		var t2 := n.cross(t1).normalized() * MARK_SIZE
		var p: Vector3 = m["pos"] + n * 0.01
		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(p - t1)
		_mesh.surface_add_vertex(p + t1)
		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(p - t2)
		_mesh.surface_add_vertex(p + t2)
	_mesh.surface_end()


# --- test accessors ---------------------------------------------------

func mark_count() -> int:
	return _marks.size()

func pulse_count() -> int:
	return _pulses

## Strength a mark at `pos` would render with (0 = invisible).
func alpha_at(pos: Vector3) -> float:
	var ear := _listener.global_position if _listener != null else global_position
	var d := ear.distance_to(pos)
	return 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL), 0.0, 1.0)
