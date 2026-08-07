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
## The echo travels as an expanding WAVE (STO-CHARACTER-041): a
## surface lights up as the wavefront sweeps over it, then dims behind
## it, and the whole wave weakens as it spreads outward.
const WAVE_SPEED := 11.0        # m/s the wavefront expands
const WAVE_THICKNESS := 1.9     # m — how wide the lit band is
const WAVE_TAIL := 0.55         # how much glow lingers behind the front
const MARK_SIZE := 0.16
const FADE_FULL := 8.0          # metres: closer than this = full strength
const FADE_NONE := 34.0         # metres: beyond this = invisible
const MAX_MARKS := 900

## Live wavefronts. Each: {origin, born, strength, radius, marks},
## where marks are {pos, normal, dist} — dist from the pulse origin,
## which is what makes the wave sweep outward over the geometry.
var _pulses_live: Array = []
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

	var marks: Array = []
	for i in RAYS_PER_PULSE:
		var dir := _sphere_dir(i)
		var q := PhysicsRayQueryParameters3D.create(
				origin, origin + dir * radius, WORLD_MASK)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var pos: Vector3 = hit["position"]
		marks.append({
			"pos": pos,
			"normal": hit["normal"],
			"dist": origin.distance_to(pos),
		})
	if marks.is_empty():
		return
	_pulses_live.append({
		"origin": origin,
		"born": Time.get_ticks_msec(),
		"strength": strength,
		"radius": radius,
		"marks": marks,
	})


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


## A pulse dies once its wavefront (plus the glow trailing behind it)
## has swept past everything it could reach.
func _expire_marks() -> void:
	var now := Time.get_ticks_msec()
	var live: Array = []
	for p in _pulses_live:
		var elapsed := float(now - int(p["born"])) / 1000.0
		var front := elapsed * WAVE_SPEED
		if front <= float(p["radius"]) + WAVE_THICKNESS * (1.0 + WAVE_TAIL * 2.0):
			live.append(p)
	_pulses_live = live


## Brightness of a surface at `dist` from the pulse origin when the
## wavefront has reached `front`. Bright at the front, trailing off
## behind it, dark ahead of it — and the whole wave weakens as it
## spreads out (energy over a bigger and bigger shell).
func _wave_brightness(dist: float, front: float, radius: float) -> float:
	var delta := front - dist
	if delta < 0.0:
		# The wave hasn't arrived here yet — still dark.
		var lead := -delta / (WAVE_THICKNESS * 0.35)
		if lead > 1.0:
			return 0.0
		return 1.0 - lead
	# Behind the front: a longer, softer tail.
	var tail := delta / (WAVE_THICKNESS * (1.0 + WAVE_TAIL * 2.0))
	if tail > 1.0:
		return 0.0
	var band := 1.0 - tail
	# Spreading loss: the further the front has travelled, the weaker.
	var spread := 1.0 - clampf(front / maxf(radius, 0.01), 0.0, 1.0) * 0.75
	return band * spread


func _rebuild_mesh() -> void:
	_mesh.clear_surfaces()
	if _pulses_live.is_empty():
		return
	var now := Time.get_ticks_msec()
	var ear := _listener.global_position if _listener != null else global_position
	var began := false

	for p in _pulses_live:
		var elapsed := float(now - int(p["born"])) / 1000.0
		var front := elapsed * WAVE_SPEED
		var strength := float(p["strength"])
		var radius := float(p["radius"])
		for m in p["marks"]:
			var alpha := _wave_brightness(float(m["dist"]), front, radius) * strength
			if alpha <= 0.01:
				continue
			# Fainter with distance from the Sniper (operator decision).
			var d: float = ear.distance_to(m["pos"])
			alpha *= 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL),
					0.0, 1.0)
			if alpha <= 0.01:
				continue
			if not began:
				_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
				began = true
			var col := Color(0.55, 0.85, 1.0, alpha)
			# A small cross lying ON the surface, so walls read as walls.
			var n: Vector3 = m["normal"]
			var t1 := n.cross(Vector3.UP)
			if t1.length() < 0.01:
				t1 = n.cross(Vector3.RIGHT)
			t1 = t1.normalized() * MARK_SIZE
			var t2 := n.cross(t1).normalized() * MARK_SIZE
			var pos: Vector3 = m["pos"] + n * 0.01
			_mesh.surface_set_color(col)
			_mesh.surface_add_vertex(pos - t1)
			_mesh.surface_add_vertex(pos + t1)
			_mesh.surface_set_color(col)
			_mesh.surface_add_vertex(pos - t2)
			_mesh.surface_add_vertex(pos + t2)
	if began:
		_mesh.surface_end()


# --- test accessors ---------------------------------------------------

func mark_count() -> int:
	var n := 0
	for p in _pulses_live:
		n += p["marks"].size()
	return n

func pulse_count() -> int:
	return _pulses

func live_wave_count() -> int:
	return _pulses_live.size()

## Every live mark, flattened (for tests).
func all_marks() -> Array:
	var out: Array = []
	for p in _pulses_live:
		out.append_array(p["marks"])
	return out

## Where each live wavefront has expanded to, in metres.
func wave_fronts() -> Array:
	var now := Time.get_ticks_msec()
	var out: Array = []
	for p in _pulses_live:
		out.append(float(now - int(p["born"])) / 1000.0 * WAVE_SPEED)
	return out

## Brightness a surface `dist` from a wave's origin shows when the
## front has reached `front` (for tests).
func brightness_for(dist: float, front: float, radius := 10.0) -> float:
	return _wave_brightness(dist, front, radius)

## Strength a mark at `pos` would render with (0 = invisible).
func alpha_at(pos: Vector3) -> float:
	var ear := _listener.global_position if _listener != null else global_position
	var d := ear.distance_to(pos)
	return 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL), 0.0, 1.0)
