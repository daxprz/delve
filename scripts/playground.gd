class_name Playground
extends Node3D
## Procedurally builds a little obstacle playground (EPI-WORLD-PLAYGROUND):
##   - a movable physics box the player can push around (STO-WORLD-001)
##   - a wall and a row of stepped pillars to jump between (STO-WORLD-002)
## Everything is generated from code and added to the main scene.

# --- Movable box ---
@export var box_size: float = 0.8
@export var box_mass: float = 2.0
@export var box_position: Vector3 = Vector3(2.5, 1.0, -3.0)

# --- Wall (big — a proper climbing/swinging wall) ---
@export var wall_size: Vector3 = Vector3(24.0, 10.0, 0.8)
@export var wall_position: Vector3 = Vector3(-9.0, 5.0, -11.0)

# --- Pillars (stepped heights so you can hop up them) ---
@export var pillar_footprint: float = 1.0
@export var pillar_heights: PackedFloat32Array = [0.6, 1.2, 1.8, 2.4, 1.4]
@export var pillar_start: Vector3 = Vector3(4.0, 0.0, -5.0)
@export var pillar_spacing: float = 1.9

var _box_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D
var _pillar_mat: StandardMaterial3D


func _ready() -> void:
	_box_mat = _mat(Color(0.85, 0.55, 0.25))     # warm crate
	_wall_mat = _mat(Color(0.5, 0.5, 0.55))       # grey wall
	_pillar_mat = _mat(Color(0.45, 0.6, 0.5))     # mossy pillars

	_build_box()
	_build_wall()
	_build_pillars()

	print("[PLAYGROUND] built: 1 movable box, 1 wall, %d pillars"
			% pillar_heights.size())


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m


## A movable RigidBody box. The player pushes it via slide collisions
## (see player.gd), and the arms can grab it.
func _build_box() -> void:
	var body := RigidBody3D.new()
	body.name = "MovableBox"
	body.mass = box_mass
	body.position = box_position
	# The Grabber can throw/pull it (STO-CHARACTER-026/027).
	body.add_to_group("grabbable")
	# Low friction so the player can actually shove it around the floor.
	var phys := PhysicsMaterial.new()
	phys.friction = 0.15
	body.physics_material_override = phys
	# Thrown at ~22 m/s it would cover 0.37 m per tick — more than a
	# procmap wall is thick — and tunnel straight through
	# (STO-ENEMIES-010). Sweep instead.
	body.continuous_cd = true

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3.ONE * box_size
	shape.shape = box_shape
	body.add_child(shape)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE * box_size
	mesh.mesh = box_mesh
	mesh.material_override = _box_mat
	body.add_child(mesh)

	add_child(body)


## A solid static wall.
func _build_wall() -> void:
	var wall := _static_box("Wall", wall_size, _wall_mat)
	wall.position = wall_position
	add_child(wall)


## A row of static pillars at stepped heights for jumping between.
func _build_pillars() -> void:
	for i in pillar_heights.size():
		var h := pillar_heights[i]
		var size := Vector3(pillar_footprint, h, pillar_footprint)
		var pillar := _static_box("Pillar%d" % i, size, _pillar_mat)
		# Sit each pillar on the ground (origin at its centre).
		pillar.position = pillar_start + Vector3(
				i * pillar_spacing, h * 0.5, 0.0)
		add_child(pillar)


## Build a StaticBody3D box with matching collision + mesh.
func _static_box(node_name: String, size: Vector3, material: StandardMaterial3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	body.add_child(mesh)
	return body
