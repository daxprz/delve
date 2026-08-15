class_name SpiderSolid
extends Node3D
## The spider made of real physics, held up by its feet
## (STO-ENEMIES-055).
##
## > "i want every part of the spider be colidble with every thing so
## > like a ragdoll make it have a stick point the bottem of the leg
## > mucles so it doesnt just ragdoll and be on the floor and if you can
## > make the legs colidable with eachother" — operator, 2026-08-15
##
## ## Why this shape, after two failures
##
## Both previous attempts (STO-ENEMIES-041) kept the animation and tried
## to FORBID poses that entered geometry. Both achieved nothing, for the
## reason written into that story: refusing a pose freezes a joint
## angle, but where a limb *is* depends on the angle **and where the
## body is** — and the body walks forward, carrying the frozen limb in
## anyway.
##
## Here there is nothing to forbid. Each limb segment is a rigid body,
## and a rigid body cannot be inside a wall because the solver will not
## allow it. Collision stops being a rule we enforce and becomes
## something that is simply true.
##
## ## An ACTIVE ragdoll, not a dead one
##
## A plain ragdoll would fall in a heap. So every bone is driven toward
## the pose the gait wants — a spring pulling it there, not a teleport
## putting it there. When the drive and a wall disagree, **the wall
## wins**, which is the entire point.
##
## Springs and not teleports is load-bearing: teleporting a physics body
## every frame is an infinite acceleration as far as the solver is
## concerned, and it is exactly what made a dragged victim thrash its
## head above the hand holding it (STO-ENEMIES-051).
##
## ## The stick point
##
## The operator's own answer to "won't it collapse?": the bottom of each
## leg gets stuck to the ground. A planted foot is driven far harder
## than the rest of the limb and is held down, so the body is held UP by
## legs that are held DOWN. Lifting a foot to step is simply easing that
## grip off, which is what walking is.

## Which bones exist, and their share of the creature's mass. Named to
## match the visual body so each physics bone knows what it is copying.
const BONES: Array = ["Upper", "Lower", "Foot"]
## How hard a bone is pulled toward the pose the gait asks for, and how
## much of its own motion resists that — a spring and its damper. Stiff
## enough to hold a leg up (these bones have no gravity), soft enough
## that a wall can win the argument.
const DRIVE := 1.0
const STIFF := 220.0
const DAMP := 26.0
## The most force a bone may ever be given, per kilogram. A ceiling, so
## one bone trapped behind geometry cannot wind up an unbounded
## correction and fire the creature across the map when it comes free.
## Measured, not chosen: at 900 N/kg a foot sat 0.44 m INSIDE a slab it
## was demonstrably in contact with — the solver detected the collision
## and the drive simply won the argument. A drive that always wins is
## not physics, it is animation with extra steps.
const MAX_FORCE := 110.0
## A planted foot is gripped much harder than the rest of the limb —
## this is the "stick point".
const FOOT_GRIP := 1.6
## Physics layer for the spider's own parts. Its own layer so limbs can
## be told to collide with EACH OTHER without every raycast in delve
## suddenly finding a forest of spider legs.
const LIMB_LAYER := 4
const BoneScript := preload("res://scripts/spider_bone.gd")
## Further than this from where it belongs and a bone is considered
## lost, and put back. A safety net, not a mechanism: if this fires
## often, something else is wrong.
## Raised from 3.0: a bone HELD BACK BY A WALL while the gait walks on
## is exactly the situation this feature exists to create, and at 3 m
## the safety net fired constantly and teleported blocked bones into
## the slab — reporting the animated spider's own penetration to three
## decimal places. It must only catch bones that are genuinely lost, and
## a 5.4 m leg can be a long way from its target while working
## perfectly.
const LOST_DISTANCE := 12.0
## How hard a bone is spun toward the direction the gait wants it to
## point. Separate from the linear drive because a bone jammed against
## something should still be free to turn.
const SPIN_DRIVE := 9.0


var _bones: Array = []          # {rb, node, len}
var _body: Node3D               # the animated quadruped body
var _built := false
var _creature: Node


## Build physics bones mirroring every leg segment of `body`.
## Returns how many were made.
func build(body: Node3D, creature: Node = null) -> int:
	_body = body
	_creature = creature
	if _body == null or not _body.has_method("limb_segments"):
		return 0
	var segs: Array = _body.call("limb_segments")
	if segs.is_empty():
		return 0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.16, 0.16)
	mat.roughness = 0.85

	for s in segs:
		var a: Vector3 = s["a"]
		var b: Vector3 = s["b"]
		var r: float = float(s["r"])
		var length: float = a.distance_to(b)
		if length < 0.02:
			continue
		var rb: RigidBody3D = BoneScript.new()
		rb.name = "Bone_" + String(s["name"]).replace("/", "_")
		# Its own layer, colliding with the world AND with itself, which
		# is the thing the operator asked for twice.
		rb.collision_layer = LIMB_LAYER
		rb.collision_mask = 1 | LIMB_LAYER
		rb.mass = maxf(0.5, length * 2.0)
		rb.can_sleep = false
		# Needed for _integrate_forces to see contacts at all
		# (STO-ENEMIES-056).
		rb.contact_monitor = true
		rb.max_contacts_reported = 6
		# Swept, not stepped. These bones are 0.08 m thick and a
		# stepping foot moves several metres a second, so without this
		# they jump clean over a wall between one tick and the next —
		# the same tunnelling that had to be fixed for thrown crates
		# (STO-ENEMIES-010), and it looks identical to "collision does
		# not work".
		rb.continuous_cd = true
		# Gravity off: these bones are held up by their drive, not by
		# standing on things. With gravity on, a leg whose drive is
		# briefly blocked sags and never recovers.
		rb.gravity_scale = 0.0
		rb.linear_damp = 4.0
		rb.angular_damp = 6.0
		add_child(rb)

		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = maxf(0.04, r)
		cap.height = maxf(cap.radius * 2.2, length)
		shape.shape = cap
		# Turned to lie ALONG the bone, exactly like the mesh below.
		#
		# A capsule's axis is its local +Y. Without this the collider
		# stuck out sideways from every limb — so the thing being
		# measured (a line down the bone) and the thing doing the
		# colliding were at right angles to each other, and the bones
		# sailed into walls while reporting solid capsules.
		shape.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		rb.add_child(shape)

		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(r * 2.0, length, r * 2.0)
		mesh.mesh = box
		mesh.material_override = mat
		mesh.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # capsule is +Y
		rb.add_child(mesh)

		rb.global_position = (a + b) * 0.5
		_bones.append({
			"rb": rb,
			"seg": s,
			"len": length,
			"limb": String(s["name"]).split("/")[0],
			"foot": String(s["name"]).ends_with("Foot"),
		})

	# Bones of the SAME leg must not collide with each other.
	#
	# Adjacent segments share a joint, so their capsules always overlap
	# — by construction, every frame, for ever. Left to fight, the
	# solver shoved them apart harder and harder and the whole skeleton
	# flew 335 m across the map on the first run. Different legs still
	# collide, which is the thing that was actually asked for.
	for i in _bones.size():
		for j in range(i + 1, _bones.size()):
			if String(_bones[i]["limb"]) == String(_bones[j]["limb"]):
				(_bones[i]["rb"] as RigidBody3D) \
						.add_collision_exception_with(_bones[j]["rb"])

	# Every bone is told about every other, so a leg brushing its own
	# creature can never be mistaken for something hitting it.
	# Kin is every bone AND the creature they belong to.
	#
	# Leaving the creature out meant its own legs kept catching on its
	# own body capsule and reporting it as an obstacle — the spider
	# tripped over itself four times on empty ground, which looked
	# exactly like the floor being mistaken for a wall.
	var all: Array = []
	if _creature != null:
		all.append(_creature)
	for bone in _bones:
		all.append(bone["rb"])
	for bone in _bones:
		(bone["rb"] as Node).set("kin", all)
		(bone["rb"] as Node).set("is_foot", bool(bone["foot"]))

	_built = not _bones.is_empty()
	print("[SOLID] %d physics bones built" % _bones.size())
	return _bones.size()


func _physics_process(delta: float) -> void:
	if not _built or _body == null or delta <= 0.0:
		return
	# Where the gait WANTS every bone to be, this instant.
	var segs: Array = _body.call("limb_segments")
	if segs.size() != _bones.size():
		return
	for i in _bones.size():
		var bone: Dictionary = _bones[i]
		var rb: RigidBody3D = bone["rb"]
		if not is_instance_valid(rb):
			continue
		var s: Dictionary = segs[i]
		var want_mid: Vector3 = (Vector3(s["a"]) + Vector3(s["b"])) * 0.5

		# Pulled, never placed. Where the pull and a wall disagree, the
		# solver settles it — and it settles in the wall's favour, which
		# is the whole reason this approach can work where refusing
		# poses could not.
		var grip: float = DRIVE * (FOOT_GRIP if bone["foot"] else 1.0)
		var off: Vector3 = want_mid - rb.global_position
		# A bone that has somehow ended up nowhere near where it belongs
		# is put back rather than flown back. Without this, one bad
		# frame becomes a permanent 26 m/s departure.
		if off.length() > LOST_DISTANCE:
			rb.global_position = want_mid
			rb.linear_velocity = Vector3.ZERO
			continue
		# A FORCE, not a velocity.
		#
		# Assigning linear_velocity every frame is kinematic control by
		# another name: the solver resolves the contact and then we
		# command the bone straight back into the wall. Measured, that
		# put the bones 0.679 m inside a slab — to three decimal places
		# the animated spider's own number, because it was the animated
		# spider's behaviour wearing a rigid body.
		#
		# A force can be OPPOSED. When the drive and a contact disagree,
		# the solver adds them up and the wall wins, which is the entire
		# point of this story.
		var push: Vector3 = (off * grip * STIFF
				- rb.linear_velocity * DAMP) * rb.mass
		if push.length() > MAX_FORCE * rb.mass:
			push = push.normalized() * MAX_FORCE * rb.mass
		rb.apply_central_force(push)

		# Point it along the bone it is copying — by SPINNING it there,
		# not by setting its transform.
		#
		# Assigning global_transform to a rigid body is a teleport, and
		# a teleport walks straight through walls. The first working
		# version of this did exactly that and reported the physics
		# bones buried 0.679 m in a slab — precisely the animated
		# spider's number, because it was precisely the animated
		# spider's behaviour wearing a rigid body.
		var along: Vector3 = Vector3(s["b"]) - Vector3(s["a"])
		if along.length() > 0.001:
			var facing: Vector3 = -rb.global_transform.basis.z
			var axis: Vector3 = facing.cross(along.normalized())
			if axis.length() > 0.0001:
				rb.angular_velocity = axis.normalized() \
						* facing.angle_to(along.normalized()) * SPIN_DRIVE
			else:
				rb.angular_velocity = Vector3.ZERO


## Where each physics bone actually ended up — what the WORLD thinks the
## spider's shape is, as opposed to what the gait asked for. Tests
## compare these against the requested pose.
func bone_segments() -> Array:
	var out: Array = []
	for bone in _bones:
		var rb: RigidBody3D = bone["rb"]
		if not is_instance_valid(rb):
			continue
		var half: Vector3 = -rb.global_transform.basis.z * (float(bone["len"]) * 0.5)
		out.append({
			"a": rb.global_position - half,
			"b": rb.global_position + half,
			"r": float((bone["seg"] as Dictionary)["r"]),
			"leg": int((bone["seg"] as Dictionary)["leg"]),
			"name": String((bone["seg"] as Dictionary)["name"]),
		})
	return out


func bone_count() -> int:
	return _bones.size()


## The hardest knock any leg has taken since this was last asked, in
## metres per second. Zero means nothing has hit it.
##
## Asking clears them, so a single knock cannot stumble the creature
## twice.
func take_knock() -> float:
	var worst := 0.0
	for bone in _bones:
		var rb = bone["rb"]
		if is_instance_valid(rb) and rb.has_method("take_knocks"):
			worst = maxf(worst, float(rb.call("take_knocks")))
	return worst
