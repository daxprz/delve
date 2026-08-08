class_name EnemyRagdoll
extends Node3D
## A REAL physics ragdoll (STO-ENEMIES-006), procedurally generated
## from a live procedural Body: one RigidBody3D per major part, built
## at the body's CURRENT pose with its actual segment sizes, material
## and per-individual mass, connected with cone-twist joints. Momentum
## carries in through launch(); the physics engine does the rest.

const TOTAL_MASS := 60.0  # kg for a nominal (mass_scale 1.0) build

## Parts: name -> path of the Body joint whose mesh becomes the part,
## plus its share of the total mass.
const PARTS := [
	{"n": "Pelvis", "p": "Pelvis", "f": 0.20},
	{"n": "Torso", "p": "Pelvis/Torso", "f": 0.28},
	{"n": "Head", "p": "Pelvis/Torso/Neck/Head", "f": 0.10},
	{"n": "UpperArmL", "p": "Pelvis/Torso/ShoulderL/UpperArmL", "f": 0.05},
	{"n": "UpperArmR", "p": "Pelvis/Torso/ShoulderR/UpperArmR", "f": 0.05},
	{"n": "ForearmL", "p": "Pelvis/Torso/ShoulderL/UpperArmL/ForearmL", "f": 0.04},
	{"n": "ForearmR", "p": "Pelvis/Torso/ShoulderR/UpperArmR/ForearmR", "f": 0.04},
	{"n": "ThighL", "p": "Pelvis/HipL/ThighL", "f": 0.08},
	{"n": "ThighR", "p": "Pelvis/HipR/ThighR", "f": 0.08},
	{"n": "ShinL", "p": "Pelvis/HipL/ThighL/ShinL", "f": 0.04},
	{"n": "ShinR", "p": "Pelvis/HipR/ThighR/ShinR", "f": 0.04},
]

## Joints: part a <-> part b, anchored at a Body joint node. Cone-twist
## everywhere; tighter spans on elbows/knees/neck.
const JOINTS := [
	{"a": "Pelvis", "b": "Torso", "at": "Pelvis/Torso", "swing": 0.6},
	{"a": "Torso", "b": "Head", "at": "Pelvis/Torso/Neck/Head", "swing": 0.5},
	{"a": "Torso", "b": "UpperArmL", "at": "Pelvis/Torso/ShoulderL", "swing": 1.0},
	{"a": "Torso", "b": "UpperArmR", "at": "Pelvis/Torso/ShoulderR", "swing": 1.0},
	{"a": "UpperArmL", "b": "ForearmL",
		"at": "Pelvis/Torso/ShoulderL/UpperArmL/ForearmL", "swing": 0.5},
	{"a": "UpperArmR", "b": "ForearmR",
		"at": "Pelvis/Torso/ShoulderR/UpperArmR/ForearmR", "swing": 0.5},
	{"a": "Pelvis", "b": "ThighL", "at": "Pelvis/HipL", "swing": 0.9},
	{"a": "Pelvis", "b": "ThighR", "at": "Pelvis/HipR", "swing": 0.9},
	{"a": "ThighL", "b": "ShinL", "at": "Pelvis/HipL/ThighL/ShinL", "swing": 0.5},
	{"a": "ThighR", "b": "ShinR", "at": "Pelvis/HipR/ThighR/ShinR", "swing": 0.5},
]

## Ragdoll parts live on their OWN physics layer: they collide with
## the world but nothing queries them as ordinary bodies. The tail
## masks this layer out so a tumbling ragdoll can't drag the Verlet
## chain around (STO-ENEMIES-009).
const RAGDOLL_LAYER := 2
const PartScript := preload("res://scripts/ragdoll_part.gd")

## Velocity limiting lives in ragdoll_part.gd's _integrate_forces —
## inside the physics step, where it can actually prevent a bad
## contact instead of cleaning up after one.

var _parts: Dictionary = {}  # name -> RigidBody3D
## Joint that holds each part ONTO its parent, keyed by the child part
## name. Tearing a limb off is just freeing its joint (STO-ENEMIES-012).
var _held_by: Dictionary = {}   # child part name -> ConeTwistJoint3D
## Parts no longer attached to the body.
var _detached: Dictionary = {}  # part name -> true


## Build parts + joints from the body's current pose. Returns the
## number of rigid parts created. Call AFTER adding self to the tree.
func build_from_body(body: Node3D, mass_scale: float) -> int:
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.9
	pmat.bounce = 0.05

	for def in PARTS:
		var joint_node := body.get_node_or_null(def["p"]) as Node3D
		if joint_node == null:
			continue
		var mesh := _first_mesh(joint_node)
		if mesh == null:
			continue
		var rb := RigidBody3D.new()
		rb.name = def["n"]
		rb.mass = TOTAL_MASS * mass_scale * def["f"]
		rb.physics_material_override = pmat
		rb.linear_damp = 0.1
		rb.angular_damp = 1.2
		# Own layer, world-only mask: adjacent parts spawn overlapping,
		# and part-vs-part contacts explode the joint solver. Parts
		# collide with the world (layer 1) but never with each other.
		rb.collision_layer = RAGDOLL_LAYER
		rb.collision_mask = 1
		# Clamp velocities INSIDE the physics step (STO-ENEMIES-010).
		# Post-step clamping in _physics_process was too late: a part
		# that tunnelled into a thin wall was already ejected, and the
		# joints had already been yanked past their limits.
		rb.set_script(PartScript)
		# With velocities bounded by the part script, sweeping is now
		# stable (unbounded + CCD fought the joints badly) and stops
		# parts passing through 0.3 m walls.
		rb.continuous_cd = true
		add_child(rb)
		rb.global_transform = mesh.global_transform.orthonormalized()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = (mesh.mesh as BoxMesh).size
		cs.shape = bs
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh.mesh
		mi.material_override = mesh.material_override
		rb.add_child(mi)
		_parts[def["n"]] = rb

	for jd in JOINTS:
		if not (_parts.has(jd["a"]) and _parts.has(jd["b"])):
			continue
		var anchor := body.get_node_or_null(jd["at"]) as Node3D
		if anchor == null:
			continue
		var joint := ConeTwistJoint3D.new()
		joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, jd["swing"])
		joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, 0.4)
		add_child(joint)
		# ConeTwist's twist axis is the joint's LOCAL X. Our limbs run
		# along local Y, so remap (x <- -y, y <- x, z <- z; still
		# right-handed) or every joint spawns violated and the solver
		# explodes the ragdoll.
		var b := anchor.global_transform.basis.orthonormalized()
		var jb := Basis(-b.y, b.x, b.z)
		joint.global_transform = Transform3D(jb, anchor.global_position)
		joint.node_a = joint.get_path_to(_parts[jd["a"]])
		joint.node_b = joint.get_path_to(_parts[jd["b"]])
		_held_by[jd["b"]] = joint

	return _parts.size()


## Tear a part off the body (STO-ENEMIES-012).
##
## All that holds a limb on is the joint whose node_b is that part, so
## taking it off is a matter of freeing that one joint. Anything
## hanging further down stays attached to what came off — pull an
## upper arm and the forearm goes with it, which is what you want.
func detach(part_name: String) -> bool:
	if not _parts.has(part_name) or _detached.has(part_name):
		return false
	var joint: Node = _held_by.get(part_name)
	if joint == null:
		return false      # the pelvis: nothing holds it on
	_held_by.erase(part_name)
	joint.queue_free()
	_detached[part_name] = true
	# A loose limb is just another object in the world. It keeps the
	# ragdoll layer so it still cannot jostle the parts it fell off.
	var rb := _parts[part_name] as RigidBody3D
	rb.angular_damp = 0.6     # tumbles more freely once it is off
	return true


func is_detached(part_name: String) -> bool:
	return _detached.has(part_name)


func detached_count() -> int:
	return _detached.size()


## The part nearest a point — used to work out WHICH limb a blow hit.
func nearest_part(point: Vector3) -> String:
	var best := ""
	var best_d := INF
	for pname in _parts:
		var rb := _parts[pname] as RigidBody3D
		if rb == null or _detached.has(pname):
			continue
		var d := rb.global_position.distance_to(point)
		if d < best_d:
			best_d = d
			best = pname
	return best


## Momentum in: every part inherits the enemy's velocity plus the hit
## dv; the struck parts (torso/head for blows, shins for sweeps) get
## extra — the joints turn that difference into real rotation.
func launch(base_velocity: Vector3, dv: Vector3, hit_parts: Array) -> void:
	for pname in _parts:
		(_parts[pname] as RigidBody3D).linear_velocity = base_velocity + dv * 0.8
	for hn in hit_parts:
		if _parts.has(hn):
			(_parts[hn] as RigidBody3D).linear_velocity += dv * 0.6


## Extra hit while already ragdolled.
func shove(dv: Vector3) -> void:
	for pname in _parts:
		(_parts[pname] as RigidBody3D).linear_velocity += dv


func part(pname: String) -> RigidBody3D:
	return _parts.get(pname)


func part_count() -> int:
	return _parts.size()


func pelvis_position() -> Vector3:
	var p: RigidBody3D = _parts.get("Pelvis")
	return p.global_position if p != null else global_position


func head_position() -> Vector3:
	var h: RigidBody3D = _parts.get("Head")
	return h.global_position if h != null else pelvis_position()


func at_rest() -> bool:
	var p: RigidBody3D = _parts.get("Pelvis")
	return p == null or p.linear_velocity.length() < 0.7


func _first_mesh(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D:
			return c
	return null
