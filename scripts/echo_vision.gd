class_name EchoVision
extends Node3D
## Echo-sight for the blind Sniper (STO-CHARACTER-040/050).
##
## The Sniper's camera renders nothing at all — its cull mask drops the
## world's visual layer — so the screen is black. Everything it knows
## is drawn here, as marks left on the surfaces of the room.
##
## Two kinds of mark, deliberately different colours so you can tell
## memory from movement at a glance:
##
##   LIDAR (white)  — an aimed RMB sweep. Long-lived: the room you
##                    scanned stays in your memory for minutes, fading
##                    white -> grey -> black. This is your map.
##   SOUND (red)    — something happened. Footsteps, gunshots,
##                    punches, bodies hitting the floor. Fades
##                    red -> grey-red -> black-red. This is your alarm.
##
## Operator decisions:
##   - only the room is outlined by SOUND, never the creature itself
##     (2026-08-07);
##   - the lidar may show creatures, and paints them red (2026-08-07);
##   - lidar memory lasts 5 minutes and a fresh sweep REPLACES the old
##     marks near each new hit, so rescanning refreshes rather than
##     piling up (2026-08-07).

## Visual layer the marks are drawn on. The Sniper's camera sees ONLY
## this layer; every other camera ignores it.
const ECHO_LAYER := 2
## World geometry lives on physics layer 1.
const WORLD_MASK := 1

# --- what makes a sound -----------------------------------------------
const PULSE_INTERVAL := 0.12    # min seconds between footstep pulses per mover
const MIN_MOVE_SPEED := 0.35    # slower than this makes no sound
const RAYS_PER_PULSE := 26
const PULSE_RADIUS_BASE := 6.5
const PULSE_RADIUS_PER_SPEED := 0.9
const PULSE_RADIUS_MAX := 16.0
const STRENGTH_FLOOR := 0.72
## Heavier creatures are louder, from their generated build.
const LOUDNESS_MIN := 0.7
const LOUDNESS_MAX := 1.55
const QUIET_FLOOR := 0.3

# --- the lidar --------------------------------------------------------
## 4x the rays of the first version: a sweep should draw a room, not
## sketch it.
const SCAN_RAYS := 600
const BLAST_RAYS := 320         # a gunshot lights everything at once
## Memory, not a glimpse: a scanned room stays with you for minutes.
const LIDAR_LIFETIME := 300.0   # 5 minutes
const SOUND_LIFETIME := 22.0    # noises fade far sooner than the map
## A fresh hit clears older LIDAR marks this close to it, so repeated
## sweeps refresh the picture instead of stacking thousands of dots.
const REPLACE_RADIUS := 0.35
## Gaussian spread: rays cluster around where you are actually looking
## and thin out toward the edge of the cone, so the middle of your
## attention is drawn in far more detail.
const CONE_SIGMA := 0.42        # fraction of the half-angle, 1 sigma

const MARK_SIZE := 0.16
const ENEMY_MARK_SCALE := 4.0
const FADE_FULL := 8.0          # metres: closer than this = full strength
const FADE_NONE := 34.0         # beyond this = inaudible
const MAX_MARKS := 9000         # hard cap; oldest go first
const REBUILD_INTERVAL := 0.08  # seconds between mesh rebuilds
## Sound still travels (STO-CHARACTER-041): a mark stays dark until
## the wavefront reaches it, so a noise ripples outward from wherever
## it happened before settling into the picture and fading.
const WAVE_SPEED := 11.0

enum Kind { LIDAR, SOUND }
## What a ray struck. The COLOUR says what it is; the shade says how
## long ago you learned it (STO-CHARACTER-051).
enum Target { WORLD, ENEMY, PLAYER }

## Fresh colours. Everything fades toward black as it ages.
const COLOUR_WORLD := Color(0.35, 0.62, 1.0)    # blue   — the room
const COLOUR_ENEMY := Color(1.0, 0.22, 0.22)    # red    — a threat
const COLOUR_PLAYER := Color(0.3, 1.0, 0.42)    # green  — a friend
## Creatures are drawn bigger so a couple of ray hits still read.
const CREATURE_DOT_SCALE := 2.6

## Every live mark: {pos, normal, born, kind, strength, enemy}
var _marks: Array = []
## pos snapped to a grid -> indices, so a fresh hit can find the old
## marks it should replace without scanning the whole list.
var _grid: Dictionary = {}
var _mesh: ImmediateMesh
var _mesh_node: MeshInstance3D
var _cooldowns: Dictionary = {}
var _last_pos: Dictionary = {}
var _listener: Node3D
var _pulses := 0
var _scans := 0
var _rebuild_timer := 0.0
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
	mat.use_point_size = true
	mat.point_size = 5.0
	_mesh_node.material_override = mat
	add_child(_mesh_node)
	if Engine.has_singleton("Sounds"):
		pass
	# Anything anyone does, anywhere, is a sound we might hear.
	if has_node("/root/Sounds"):
		get_node("/root/Sounds").sound_made.connect(_on_sound_made)


func _physics_process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = float(_cooldowns[key]) - delta
	_scan_movers(delta)
	_expire()
	_rebuild_timer += delta
	if _rebuild_timer >= REBUILD_INTERVAL:
		_rebuild_timer = 0.0
		_rebuild_mesh()


# ---------------------------------------------------------------------
# Hearing
# ---------------------------------------------------------------------

## Anything that moved this tick makes footsteps.
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


## A footstep-style noise: rays outward, marks on the ROOM only.
func emit_pulse(origin: Vector3, speed: float, source: Node3D = null) -> void:
	var loud := _loudness_of(source)
	var radius := clampf(
			(PULSE_RADIUS_BASE + speed * PULSE_RADIUS_PER_SPEED) * loud,
			PULSE_RADIUS_BASE * LOUDNESS_MIN, PULSE_RADIUS_MAX)
	var strength := clampf(clampf(speed / 6.0, STRENGTH_FLOOR, 1.0) * loud,
			QUIET_FLOOR, 1.0)
	_pulses += 1
	_cast(origin, radius, strength, source, RAYS_PER_PULSE, Kind.SOUND,
			false, Vector3.ZERO, 0.0)


## Something HAPPENED here — a gunshot, a punch, a body hitting the
## floor (STO-CHARACTER-050). Louder and wider than a footstep, and it
## does not care who made it, so other players' actions show up too.
func _on_sound_made(position: Vector3, loudness: float) -> void:
	var radius := clampf(10.0 * loudness, 6.0, 60.0)
	var rays := clampi(int(40.0 * loudness), 30, BLAST_RAYS)
	_pulses += 1
	_cast(position, radius, 1.0, null, rays, Kind.SOUND,
			false, Vector3.ZERO, 0.0)


## The gunshot: the whole room at once.
func emit_blast(origin: Vector3, radius := 45.0) -> void:
	_pulses += 1
	_cast(origin, radius, 1.0, null, BLAST_RAYS, Kind.SOUND,
			false, Vector3.ZERO, 0.0)


# ---------------------------------------------------------------------
# Lidar
# ---------------------------------------------------------------------

## An aimed sweep. Dense, gaussian-clustered around where you look,
## and remembered for minutes.
func emit_scan(origin: Vector3, dir: Vector3, radius := 40.0,
		half_angle_deg := 32.0, rays := SCAN_RAYS, _linger := 0.0) -> void:
	_scans += 1
	_cast(origin, radius, 1.0, null, rays, Kind.LIDAR,
			true, dir.normalized(), deg_to_rad(half_angle_deg))


func _cast(origin: Vector3, radius: float, strength: float,
		source: Node3D, rays: int, kind: int, include_creatures: bool,
		cone_axis: Vector3, cone_angle: float) -> void:
	var space := get_world_3d().direct_space_state
	# Creatures are now legitimate targets for BOTH lidar and sound
	# (STO-CHARACTER-051): you want to see the enemy, not just the wall
	# behind it. Only whatever MADE the noise is skipped, so a footstep
	# does not simply paint its own owner.
	var exclude: Array = []
	if source != null and source is CollisionObject3D:
		exclude.append((source as CollisionObject3D).get_rid())
	var now := Time.get_ticks_msec()

	for i in rays:
		var dir := _cone_dir(cone_axis, cone_angle) \
				if cone_angle > 0.0 else _sphere_dir(i, rays)
		var q := PhysicsRayQueryParameters3D.create(
				origin, origin + dir * radius, WORLD_MASK)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var pos: Vector3 = hit["position"]
		var col = hit.get("collider")
		var target := Target.WORLD
		if col is Node:
			if (col as Node).is_in_group("enemies"):
				target = Target.ENEMY
			elif (col as Node).is_in_group("players"):
				target = Target.PLAYER
		# A fresh lidar hit REPLACES the stale picture around it, so
		# rescanning a room refreshes it rather than layering dots.
		if kind == Kind.LIDAR:
			_clear_near(pos, REPLACE_RADIUS)
		_add_mark({
			"pos": pos,
			"normal": hit["normal"],
			"born": now,
			# The wave has to travel here before this spot lights up.
			"delay": origin.distance_to(pos) / WAVE_SPEED,
			"kind": kind,
			"strength": strength,
			"target": target,
		})

	if _marks.size() > MAX_MARKS:
		_marks = _marks.slice(_marks.size() - MAX_MARKS)
		_reindex()


# ---------------------------------------------------------------------
# Mark storage (a coarse spatial grid, so replacement stays cheap)
# ---------------------------------------------------------------------

const CELL := 0.5


func _cell_of(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x / CELL), floori(p.y / CELL), floori(p.z / CELL))


func _add_mark(m: Dictionary) -> void:
	_marks.append(m)
	var c := _cell_of(m["pos"])
	if not _grid.has(c):
		_grid[c] = []
	_grid[c].append(_marks.size() - 1)


## Drop LIDAR marks within `radius` of `p` — the old reading of a spot
## we have just re-measured.
func _clear_near(p: Vector3, radius: float) -> void:
	var c := _cell_of(p)
	var r2 := radius * radius
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var key := Vector3i(c.x + dx, c.y + dy, c.z + dz)
				if not _grid.has(key):
					continue
				for idx in _grid[key]:
					if idx >= _marks.size():
						continue
					var m: Dictionary = _marks[idx]
					if m.get("dead", false) or int(m["kind"]) != Kind.LIDAR:
						continue
					if (m["pos"] as Vector3).distance_squared_to(p) <= r2:
						m["dead"] = true


func _reindex() -> void:
	_grid.clear()
	for i in _marks.size():
		var c := _cell_of(_marks[i]["pos"])
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(i)


func _expire() -> void:
	var now := Time.get_ticks_msec()
	var live: Array = []
	for m in _marks:
		if m.get("dead", false):
			continue
		var life: float = LIDAR_LIFETIME if int(m["kind"]) == Kind.LIDAR \
				else SOUND_LIFETIME
		if float(now - int(m["born"])) / 1000.0 - float(m.get("delay", 0.0)) < life:
			live.append(m)
	if live.size() != _marks.size():
		_marks = live
		_reindex()


# ---------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------

## Colour for a mark: WHAT it is decides the hue, HOW OLD it is
## decides the shade (STO-CHARACTER-051).
##   world  -> shades of blue
##   enemy  -> shades of red
##   friend -> shades of green
## Everything darkens toward black as it ages and then disappears.
func mark_colour(target: int, t: float) -> Color:
	var a := clampf(t, 0.0, 1.0)
	var base := COLOUR_WORLD
	if target == Target.ENEMY:
		base = COLOUR_ENEMY
	elif target == Target.PLAYER:
		base = COLOUR_PLAYER
	# Ease the darkening so a mark holds its colour for most of its
	# life and then drops away, rather than greying out immediately.
	return base.lerp(Color(0, 0, 0), a * a)


func _rebuild_mesh() -> void:
	_mesh.clear_surfaces()
	if _marks.is_empty():
		return
	var now := Time.get_ticks_msec()
	var ear := _listener.global_position if _listener != null else global_position
	var began := false

	for m in _marks:
		var kind := int(m["kind"])
		var life: float = LIDAR_LIFETIME if kind == Kind.LIDAR else SOUND_LIFETIME
		# Nothing shows until the wavefront has arrived; then it ages.
		var since := float(now - int(m["born"])) / 1000.0 - float(m.get("delay", 0.0))
		if since < 0.0:
			continue
		var t := since / life
		if t >= 1.0:
			continue
		var col := mark_colour(int(m.get("target", Target.WORLD)), t)
		var alpha := float(m["strength"])
		# Everything is fainter the further it is from the Sniper.
		var d: float = ear.distance_to(m["pos"])
		alpha *= 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL), 0.0, 1.0)
		if alpha <= 0.02:
			continue
		col.a = alpha
		if not began:
			# Simple DOTS rather than little crosses: at 600 rays a
			# sweep the crosses smeared into a mesh, while points read
			# as a proper point-cloud of the room.
			_mesh.surface_begin(Mesh.PRIMITIVE_POINTS)
			began = true
		var n: Vector3 = m["normal"]
		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(m["pos"] + n * 0.01)
	if began:
		_mesh.surface_end()


# ---------------------------------------------------------------------
# Ray directions
# ---------------------------------------------------------------------

## A direction inside the cone, GAUSSIAN about the axis: dense where
## you are looking, thinning toward the edge.
func _cone_dir(axis: Vector3, half_angle: float) -> Vector3:
	var theta := absf(_rng.randfn(0.0, half_angle * CONE_SIGMA))
	theta = minf(theta, half_angle)
	var azimuth := _rng.randf() * TAU
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var right := axis.cross(up).normalized()
	var real_up := right.cross(axis).normalized()
	return (axis * cos(theta)
			+ right * (sin(theta) * cos(azimuth))
			+ real_up * (sin(theta) * sin(azimuth))).normalized()


func _sphere_dir(i: int, rays: int) -> Vector3:
	var k := float(i) + _rng.randf()
	var phi := acos(clampf(1.0 - 2.0 * k / float(rays), -1.0, 1.0))
	var theta := PI * (1.0 + sqrt(5.0)) * k
	return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))


func _loudness_of(source: Node3D) -> float:
	if source == null or not source.has_method("mass"):
		return 1.0
	return clampf(float(source.call("mass")), LOUDNESS_MIN, LOUDNESS_MAX)


## Echoes bounce off the room, not off people.
func _creature_rids(_source: Node3D) -> Array:
	var rids: Array = []
	for group in ["enemies", "players"]:
		for n in get_tree().get_nodes_in_group(group):
			if n is CollisionObject3D:
				rids.append((n as CollisionObject3D).get_rid())
	return rids


# --- test accessors ---------------------------------------------------

func mark_count() -> int:
	return _marks.size()

func lidar_mark_count() -> int:
	var n := 0
	for m in _marks:
		if int(m["kind"]) == Kind.LIDAR:
			n += 1
	return n

func sound_mark_count() -> int:
	var n := 0
	for m in _marks:
		if int(m["kind"]) == Kind.SOUND:
			n += 1
	return n

func enemy_mark_count() -> int:
	return target_mark_count(Target.ENEMY)


func target_mark_count(target: int) -> int:
	var n := 0
	for m in _marks:
		if int(m.get("target", Target.WORLD)) == target:
			n += 1
	return n

func pulse_count() -> int:
	return _pulses

func scan_count() -> int:
	return _scans

func all_marks() -> Array:
	return _marks

func alpha_at(pos: Vector3) -> float:
	var ear := _listener.global_position if _listener != null else global_position
	var d := ear.distance_to(pos)
	return 1.0 - clampf((d - FADE_FULL) / (FADE_NONE - FADE_FULL), 0.0, 1.0)
