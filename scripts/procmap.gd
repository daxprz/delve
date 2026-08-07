class_name ProcMap
extends Node3D
## A procedurally-generated map of ROOMS (STO-WORLD-004), separate from
## the testing playground. A grid of rooms is connected by DOORWAYS (a
## randomized-DFS spanning tree + a few extra loops), so you move room to
## room down long runs. Some rooms have an UPPER area — a raised platform
## you climb up to (no stairs; use jump / wall-jump / zip).
##
## Set `map_seed` for a different layout; the same seed regenerates the
## same map.

@export var map_seed := 1337
@export var grid_w := 5
@export var grid_h := 5
@export var cell := 7.0       # room size
@export var wall_h := 4.0
@export var door_w := 2.4     # doorway width between rooms

const WALL_T := 0.3

var _rng: RandomNumberGenerator
var _mat: StandardMaterial3D
var _up_mat: StandardMaterial3D
var _wall_count := 0
var _upper_count := 0
var _hash := 0


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = map_seed
	_mat = _make(Color(0.55, 0.57, 0.62))
	_up_mat = _make(Color(0.5, 0.6, 0.72))
	_generate()
	print("[PROCMAP] seed %d -> %d walls, %d upper areas, hash %d"
			% [map_seed, _wall_count, _upper_count, _hash])


func _make(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _o(x: float, z: float) -> Vector3:
	return Vector3(x, 0.0, z)


# --- generation ---------------------------------------------------------

func _generate() -> void:
	var carved_r: Array = []   # doorway from (x,y) to (x+1,y)
	var carved_d: Array = []   # doorway from (x,y) to (x,y+1)
	for x in grid_w:
		carved_r.append([])
		carved_d.append([])
		for y in grid_h:
			carved_r[x].append(false)
			carved_d[x].append(false)

	# Randomized DFS spanning tree (guarantees every room is reachable).
	var visited := {}
	visited["0,0"] = true
	var stack: Array = [Vector2i(0, 0)]
	while not stack.is_empty():
		var cur: Vector2i = stack[stack.size() - 1]
		var options: Array = []
		if cur.x < grid_w - 1 and not visited.has("%d,%d" % [cur.x + 1, cur.y]):
			options.append("R")
		if cur.x > 0 and not visited.has("%d,%d" % [cur.x - 1, cur.y]):
			options.append("L")
		if cur.y < grid_h - 1 and not visited.has("%d,%d" % [cur.x, cur.y + 1]):
			options.append("D")
		if cur.y > 0 and not visited.has("%d,%d" % [cur.x, cur.y - 1]):
			options.append("U")
		if options.is_empty():
			stack.pop_back()
			continue
		var dir: String = options[_rng.randi_range(0, options.size() - 1)]
		var nx := cur.x
		var ny := cur.y
		match dir:
			"R": carved_r[cur.x][cur.y] = true; nx = cur.x + 1
			"L": carved_r[cur.x - 1][cur.y] = true; nx = cur.x - 1
			"D": carved_d[cur.x][cur.y] = true; ny = cur.y + 1
			"U": carved_d[cur.x][cur.y - 1] = true; ny = cur.y - 1
		visited["%d,%d" % [nx, ny]] = true
		stack.append(Vector2i(nx, ny))

	# A few extra doorways so rooms connect in loops (not one dead-end path).
	var extra := int(grid_w * grid_h * 0.35)
	for i in extra:
		var x := _rng.randi_range(0, grid_w - 1)
		var y := _rng.randi_range(0, grid_h - 1)
		if _rng.randf() < 0.5 and x < grid_w - 1:
			carved_r[x][y] = true
		elif y < grid_h - 1:
			carved_d[x][y] = true

	_build_walls(carved_r, carved_d)
	_build_upper_areas()
	_hash = _compute_hash(carved_r, carved_d)


func _build_walls(carved_r: Array, carved_d: Array) -> void:
	var W := grid_w * cell
	var H := grid_h * cell
	# Walls between rooms: a doorway gap if connected, else a full wall.
	for x in grid_w - 1:
		for y in grid_h:
			var xw := (x + 1) * cell
			var a := _o(xw, y * cell)
			var b := _o(xw, (y + 1) * cell)
			_wall(a, b, [[cell * 0.5, door_w]] if carved_r[x][y] else [])
	for x in grid_w:
		for y in grid_h - 1:
			var zw := (y + 1) * cell
			var a := _o(x * cell, zw)
			var b := _o((x + 1) * cell, zw)
			_wall(a, b, [[cell * 0.5, door_w]] if carved_d[x][y] else [])
	# Outer walls; entrance gap in the first cell of the left wall.
	_wall(_o(0, 0), _o(0, H), [[cell * 0.5, door_w]])
	_wall(_o(W, 0), _o(W, H), [])
	_wall(_o(0, 0), _o(W, 0), [])
	_wall(_o(0, H), _o(W, H), [])


## Give a few rooms an UPPER area: a raised platform (partial upper floor)
## you climb up to with a low ledge — no stairs.
func _build_upper_areas() -> void:
	var count := 3
	for i in count:
		var cx := _rng.randi_range(0, grid_w - 1)
		var cy := _rng.randi_range(0, grid_h - 1)
		var c := _o(cx * cell + cell * 0.5, cy * cell + cell * 0.5)
		var plat_h := 2.6
		# Upper platform slab over ~half the room.
		_block(c + Vector3(cell * 0.2, plat_h, 0.0),
				Vector3(cell * 0.5, 0.3, cell * 0.85), _up_mat)
		# Support pillar under the platform's inner edge.
		_block(c + Vector3(cell * 0.0, plat_h * 0.5, cell * 0.35),
				Vector3(0.4, plat_h, 0.4), _up_mat)
		# One low ledge to start the climb (a single block, not stairs).
		_block(c + Vector3(-cell * 0.25, 0.45, 0.0),
				Vector3(1.6, 0.9, 1.6), _up_mat)
		_upper_count += 1


func _block(center: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	body.position = center
	add_child(body)


# --- wall helpers -------------------------------------------------------

func _seg(p: Vector3, q: Vector3) -> void:
	var length := p.distance_to(q)
	if length < 0.05:
		return
	var mid := (p + q) * 0.5
	var dir := (q - p) / length
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(WALL_T, wall_h, length)
	shape.shape = bs
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(WALL_T, wall_h, length)
	mi.mesh = bm
	mi.material_override = _mat
	body.add_child(mi)
	body.position = Vector3(mid.x, wall_h * 0.5, mid.z)
	body.rotation.y = atan2(dir.x, dir.z)
	add_child(body)
	_wall_count += 1


func _wall(a: Vector3, b: Vector3, doors: Array) -> void:
	var total := a.distance_to(b)
	var dir := (b - a) / total
	var pos := 0.0
	for c in doors:
		var ds: float = float(c[0]) - float(c[1]) * 0.5
		var de: float = float(c[0]) + float(c[1]) * 0.5
		if ds > pos:
			_seg(a + dir * pos, a + dir * ds)
		pos = maxf(pos, de)
	if pos < total:
		_seg(a + dir * pos, a + dir * total)


func _compute_hash(carved_r: Array, carved_d: Array) -> int:
	var h := 0
	for x in grid_w:
		for y in grid_h:
			if x < grid_w - 1 and carved_r[x][y]:
				h += x * 31 + y * 17 + 3
			if y < grid_h - 1 and carved_d[x][y]:
				h += x * 13 + y * 7 + 101
	return h


# --- test helpers ---
func wall_count() -> int:
	return _wall_count

func upper_count() -> int:
	return _upper_count

func layout_hash() -> int:
	return _hash
