class_name Spike
extends StaticBody3D
## A sharp thing standing in the world (STO-ENEMIES-033).
##
## It exists for exactly one reason: the giant spider needs somewhere to
## put you. It is not a trap — walking into it does nothing at all. Only
## the spider puts you on it (STO-ENEMIES-034).
##
## Spikes register themselves in the `spikes` group and are found by
## `Spike.nearest()`, never by a typed-in coordinate. That is what makes
## "carry them to the nearest spike" one lookup, and what makes adding a
## second spike a change to a list rather than a change to the spider.

## The group every spike joins. The spider searches this and nothing else.
const GROUP := "spikes"

## A tall, thin, nearly-pointed cone. The top radius is not quite zero:
## a true point renders as a sliver you cannot see from across a room,
## and being able to spot it from a distance — and think *don't get
## carried over there* — is the whole reason it is visible at all.
const HEIGHT := 2.4
const BASE_RADIUS := 0.28
const TIP_RADIUS := 0.03

@export var tint: Color = Color(0.34, 0.32, 0.36)


func _ready() -> void:
	add_to_group(GROUP)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.45
	mat.metallic = 0.35

	var mesh := MeshInstance3D.new()
	mesh.name = "Shaft"
	var cone := CylinderMesh.new()
	cone.top_radius = TIP_RADIUS
	cone.bottom_radius = BASE_RADIUS
	cone.height = HEIGHT
	cone.radial_segments = 7      # odd, so it reads as a jagged stake
	mesh.mesh = cone
	# The node's origin sits on the FLOOR, so placing one is just an
	# (x, 0, z) — no arithmetic at every call site to work out where the
	# middle of it should be.
	mesh.position = Vector3(0.0, HEIGHT * 0.5, 0.0)
	mesh.material_override = mat
	add_child(mesh)

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.height = HEIGHT
	cyl.radius = BASE_RADIUS * 0.6
	shape.shape = cyl
	shape.position = Vector3(0.0, HEIGHT * 0.5, 0.0)
	add_child(shape)


## Where a player ends up when they are put on this. Just below the tip,
## so they are visibly ON the thing rather than balanced atop it.
func impale_point() -> Vector3:
	return global_position + Vector3.UP * (HEIGHT * 0.78)


## The nearest spike to `point`, or null if the world has none.
##
## Static and group-driven, so nothing that uses it needs a reference to
## a particular spike, and a second spike works with no code change.
static func nearest(from_node: Node, point: Vector3) -> Node3D:
	if from_node == null or not from_node.is_inside_tree():
		return null
	var best: Node3D = null
	var best_d := INF
	for s in from_node.get_tree().get_nodes_in_group(GROUP):
		if s is not Node3D:
			continue
		var d: float = (s as Node3D).global_position.distance_to(point)
		if d < best_d:
			best_d = d
			best = s as Node3D
	return best
