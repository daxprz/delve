class_name Piston
extends AnimatableBody3D
## The Grabber\'s piston as a REAL OBJECT (STO-CHARACTER-068).
##
## STO-CHARACTER-067 delivered it as an instant hit in a radius, which
## is a normal attack wearing a piston\'s name. This is a shaft that
## actually shoots out, hits what it meets on the way, retracts, and
## then goes away.
##
## AnimatableBody3D, not Area3D: it has to be SOLID. You can stand on
## it, and it shoves what it touches because it is physically there.
##
## Its push is FIXED, not worked out from momentum — the operator asked
## for predictable, unlike the Runner\'s claws where speed is
## everything.

const THICKNESS := 0.34
## The fixed barrel at the base, and the flat face on the end.
const HOUSING_LEN := 0.55
const HEAD_LEN := 0.18
const HIT_RADIUS := 0.9
## Full charge fires at 1.25x the Runner\'s pounce (POUNCE_FORWARD 7.5).
const FULL_SPEED := 9.375
const MIN_SPEED := 3.0
const MAX_LENGTH := 6.0
const RETRACT_SPEED := 7.0
## What it launches things with. Fixed, whatever the charge.
const LAUNCH_FORCE := 24.0
## However slowly it was fired, it starts coming back after this. A
## weak shot would otherwise creep outward for seconds and leave the
## arms locked out mid-extension.
const MAX_EXTEND_TIME := 0.9

var _dir := Vector3.FORWARD
var _speed := FULL_SPEED
var _length := 0.0
var _retracting := false
var _age := 0.0
var _owner_player: Node3D
var _hit: Dictionary = {}          # instance id -> true, so one hit each
var _mesh: MeshInstance3D
var _head: MeshInstance3D
var _shape: CollisionShape3D


## Called right after adding to the tree.
func setup(from: Node3D, dir: Vector3, charge01: float) -> void:
	_owner_player = from
	_dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	# The CHARGE sets how fast the shaft flies, not how hard it hits.
	_speed = lerpf(MIN_SPEED, FULL_SPEED, clampf(charge01, 0.0, 1.0))

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.64, 0.70)
	mat.metallic = 0.9
	mat.roughness = 0.3

	# An actual piston shape (STO-CHARACTER-071), not a growing box:
	#
	#   [==housing==]======rod======[HEAD]
	#    fixed barrel  thin, extends  wide face
	#
	# Cylinders are built along Y in Godot while the shaft runs along
	# +Z, so each one is turned a quarter turn about X.
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.28, 0.30, 0.34)
	dark.metallic = 1.0
	dark.roughness = 0.45

	# The barrel: fixed length, sits at the base and never grows.
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hc := CylinderMesh.new()
	hc.top_radius = THICKNESS * 0.62
	hc.bottom_radius = THICKNESS * 0.62
	hc.height = HOUSING_LEN
	housing.mesh = hc
	housing.material_override = dark
	housing.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	housing.position = Vector3(0.0, 0.0, HOUSING_LEN * 0.5)
	add_child(housing)

	# The rod: thin, bright, and the part that extends.
	_mesh = MeshInstance3D.new()
	_mesh.name = "Rod"
	var rod := CylinderMesh.new()
	rod.top_radius = THICKNESS * 0.30
	rod.bottom_radius = THICKNESS * 0.30
	rod.height = 0.1
	_mesh.mesh = rod
	_mesh.material_override = mat
	_mesh.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_mesh)

	# The head: a wide flat face that does the shoving.
	_head = MeshInstance3D.new()
	_head.name = "Head"
	var hd := CylinderMesh.new()
	hd.top_radius = THICKNESS * 0.85
	hd.bottom_radius = THICKNESS * 0.85
	hd.height = HEAD_LEN
	_head.mesh = hd
	_head.material_override = dark
	_head.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_head)

	_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(THICKNESS, THICKNESS, 0.1)
	_shape.shape = bs
	add_child(_shape)
	_reshape()


func _physics_process(delta: float) -> void:
	_age += delta
	if _retracting:
		_length -= RETRACT_SPEED * delta
		if _length <= 0.05:
			queue_free()
			return
	else:
		_length += _speed * delta
		if _length >= MAX_LENGTH or _age >= MAX_EXTEND_TIME:
			_retracting = true
	_reshape()
	if not _retracting:
		_punch_along()


## Grow the shaft from the shoulder outward, so it reads as extending
## rather than sliding along.
func _reshape() -> void:
	var l: float = maxf(_length, 0.05)
	# Only the ROD grows; the housing stays put and the head rides on
	# the end of the rod, which is what makes it read as a piston
	# rather than a stretching block.
	(_mesh.mesh as CylinderMesh).height = l
	_mesh.position = Vector3(0.0, 0.0, l * 0.5)
	_head.position = Vector3(0.0, 0.0, l)
	(_shape.shape as BoxShape3D).size = Vector3(THICKNESS, THICKNESS, l)
	_shape.position = Vector3(0.0, 0.0, l * 0.5)


## Launch whatever the HEAD of the shaft reaches. Each thing once.
func _punch_along() -> void:
	var head := global_position + _dir * _length
	for group in ["enemies", "players"]:
		for n in get_tree().get_nodes_in_group(group):
			var node := n as Node3D
			if node == null or node == _owner_player:
				continue
			if head.distance_to(node.global_position) > HIT_RADIUS:
				continue
			var id := node.get_instance_id()
			if _hit.has(id):
				continue
			_hit[id] = true
			var push := _dir * LAUNCH_FORCE + Vector3.UP * 4.0
			if group == "players":
				# A player keeps CONTROL — no ragdoll, no damage
				# (STO-CHARACTER-067).
				if node.has_method("launch_by_piston"):
					node.call("launch_by_piston", push)
			elif node.has_method("apply_knockback"):
				# An enemy is launched AND ragdolled.
				node.call("apply_knockback", push * 3.0)


func shaft_length() -> float:
	return _length


func is_retracting() -> bool:
	return _retracting
