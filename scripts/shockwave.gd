class_name Shockwave
extends Node3D
## A shockwave burst from a powerful punch (STO-CHARACTER-009). On spawn
## it shoves every nearby RigidBody radially outward (scaled by the
## punch power) and shows a quick expanding ring, then removes itself.

const RADIUS := 4.5          # how far the shockwave reaches
const IMPULSE_SCALE := 1.2   # push strength per unit of punch power
const LIFETIME := 0.35       # visual ring duration (seconds)

## Set by the puncher before adding to the tree.
var power := 0.0
## Optional player who caused this (so damage routes through their combo).
var source: Node = null

var _age := 0.0
var _ring: MeshInstance3D
var _hit_count := 0


func _ready() -> void:
	_burst()
	_build_ring()
	print("[SHOCKWAVE] power %.1f pushed %d bodies" % [power, _hit_count])


## Push every RigidBody within RADIUS away from the centre, once.
func _burst() -> void:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = RADIUS
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), global_position)
	q.collide_with_bodies = true
	for hit in space.intersect_shape(q, 64):
		var body = hit.get("collider")
		var is_rigid := body is RigidBody3D
		var is_knockable: bool = body != null and body.has_method("apply_knockback")
		if not (is_rigid or is_knockable):
			continue
		var dir: Vector3 = body.global_position - global_position
		dir.y = maxf(dir.y, 0.2)  # bias a little upward so things pop
		if dir.length() < 0.001:
			dir = Vector3.UP
		var impulse := dir.normalized() * power * IMPULSE_SCALE
		if is_rigid:
			(body as RigidBody3D).apply_central_impulse(impulse)
		else:
			body.call("apply_knockback", impulse)
		if body.has_method("take_damage"):
			# Route through the source player's combo when we know it.
			if source != null and is_instance_valid(source) and source.has_method("deal_damage"):
				source.call("deal_damage", body, power)
			else:
				body.call("take_damage", power)
		_hit_count += 1


func _build_ring() -> void:
	_ring = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.2
	mesh.outer_radius = 0.5
	_ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = mat
	add_child(_ring)


func _process(delta: float) -> void:
	_age += delta
	var t := _age / LIFETIME
	if _ring != null:
		var s: float = lerpf(0.3, RADIUS * 2.0, t)
		_ring.scale = Vector3(s, s, s)
		var mat := _ring.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color.a = clampf(1.0 - t, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
