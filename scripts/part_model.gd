extends RefCounted
## Loads a part the operator modelled in Godot's editor
## (STO-TOOLS-011), and explains itself when the model is wrong
## (STO-TOOLS-013).
##
## Shape used to live as constants inside `mechanical_arms.gd` — eight
## numbers that had to be described to an agent in words to change. Now
## it lives in `scenes/parts/`, where it can be dragged.
##
## The code keeps three jobs: animating, scaling, and making pieces
## solid. It gives up the one it was bad at — deciding the shape.
##
## ## What a part has to look like
##
## A part is a Node3D with one or more LIMBS under it. Each limb is a
## chain of numbered joints:
##
##     Limb            <- placed and angled however you like
##     └─ J0           <- the first joint
##        ├─ Seg       <- a block you can see
##        └─ End       <- where the next joint starts (optional)
##           └─ J1
##              ├─ Seg
##              └─ End <- the tip
##
## Only three names are load-bearing: `J<number>`, `Seg` and `End`.
## Everything else — the limb names, positions, angles, sizes, colours,
## how many joints, how many limbs — is the operator's.
##
## ## Two axes, two owners
##
## `rotation.x` on a J-joint belongs to the GAME. The curl driver sets
## it every frame, so anything modelled there is overwritten before it
## is ever seen. `rotation.y` and `rotation.z`, and everything on the
## limb root, belong to the operator. That split is why the claw's
## elbow kink is on y.
##
## Deliberately NOT given a `class_name`. Global class names are not
## resolvable in headless `godot -s` runs — the class cache is not
## rebuilt — so every script here is reached by `preload` instead. Using
## one cost a full test run to rediscover.

const PARTS_DIR := "res://scenes/parts/"

## What the operator's copy is called, and the never-edited copy beside
## it. A broken model costs you your change, never your game.
const BACKUP_SUFFIX := "_default"

## The shape a limb is expected to have, quoted back in error messages
## so the fix is in the message rather than in a document somewhere.
const SHAPE_HINT := "J0 > (Seg, End > J1 > (Seg, End))"

## The last complaint printed, so a test can check the wording and so
## "it said nothing" is checkable too — a warning that always appears is
## a warning nobody reads.
static var _last_message := ""


static func last_message() -> String:
	return _last_message


static func clear_messages() -> void:
	_last_message = ""


## Load a modelled part, falling back to the untouched copy if the
## operator's is missing or broken.
##
## Returns a fresh, unparented Node3D, or null if even the backup is
## unusable. Never throws, never half-loads: a part that fails
## validation is freed and the next candidate tried, so a caller either
## gets a whole part or nothing.
static func load_part(part_name: String) -> Node3D:
	var mine := PARTS_DIR + part_name + ".tscn"
	var backup := PARTS_DIR + part_name + BACKUP_SUFFIX + ".tscn"

	# The complaint is collected but NOT printed yet: what the operator
	# needs to know is the problem AND what happened instead, in one
	# message, and "what happened instead" is not known until the backup
	# has been tried.
	var why: Array = []
	var part := _try(mine, why)
	if part != null:
		return part

	var fallback := _try(backup, why)
	if fallback != null:
		_say(mine, String(why[0]) if not why.is_empty() else "could not be used.",
				backup)
		return fallback

	# Both gone. Loud, because this is the one case where the operator
	# genuinely has no claw and needs to know why.
	push_error("[PART] neither %s nor %s could be used. "
			% [mine, backup] + "The claw will be missing. "
			+ "Restore %s from git to get it back." % backup)
	return null


## Try one file. Returns the loaded part, or null having appended a
## plain-words reason to `why`.
static func _try(path: String, why: Array) -> Node3D:
	if not ResourceLoader.exists(path):
		why.append("is missing.")
		return null

	# CACHE_MODE_REPLACE forces a re-read from disk, so an edit saved in
	# the Godot editor is picked up by the next Grabber to spawn rather
	# than the game serving the version it read at startup.
	#
	# HONESTLY: this could not be shown to be necessary. The obvious
	# stale-cache bug was sabotage-tested twice — plain `load()`, once
	# with the file rewritten via ResourceSaver and once via raw
	# FileAccess — and the test passed both times. The reason appears to
	# be that nothing here retains the PackedScene (it is instantiated
	# and dropped), so Godot frees the cache entry and re-reads anyway.
	#
	# Kept regardless, because it costs one re-parse of a 6 KB file per
	# character spawn and it stops being luck the moment anything holds
	# a reference — which STO-TOOLS-016's live reload will. But it is
	# insurance, not a demonstrated fix, and it should not be described
	# as one.
	var scene: PackedScene = ResourceLoader.load(
			path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE)
	if scene == null:
		why.append("could not be opened at all — the file may be damaged.")
		return null

	var root := scene.instantiate() as Node3D
	if root == null:
		why.append("does not start with a 3D node.")
		return null

	var problem := check(root)
	if problem != "":
		why.append(problem)
		root.queue_free()
		return null

	return root


## Check a part, and describe the FIRST thing wrong with it in words a
## person can act on. Returns "" when the part is fine.
##
## Deliberately stops at the first problem. A wall of complaints after
## one rename is not more helpful than one sentence — it is less.
static func check(root: Node3D) -> String:
	var limbs := root.get_children()
	if limbs.is_empty():
		return "is empty — there is nothing in it to build."

	for limb in limbs:
		if not (limb is Node3D):
			continue
		var problem := _check_limb(limb as Node3D)
		if problem != "":
			return problem
	return ""


static func _check_limb(limb: Node3D) -> String:
	var nm := String(limb.name)
	var joint := limb.get_node_or_null("J0") as Node3D
	if joint == null:
		return "%s has no \"J0\".\n       A limb needs: %s\n" % [nm, SHAPE_HINT] \
				+ "       Did you rename it?"

	var n := 0
	while joint != null:
		var seg := joint.get_node_or_null("Seg")
		if seg == null:
			return "%s/J%d has no \"Seg\" — the block you can see.\n" % [nm, n] \
					+ "       A limb needs: %s" % SHAPE_HINT
		if not (seg is MeshInstance3D):
			return "%s/J%d/Seg is a %s, not a block with a shape.\n" \
					% [nm, n, seg.get_class()] \
					+ "       Add a MeshInstance3D there instead."
		if (seg as MeshInstance3D).mesh == null:
			return "%s/J%d/Seg has no shape set — it would be invisible.\n" \
					% [nm, n] + "       Give it a BoxMesh."

		# `End` is optional: the last joint in a chain simply stops.
		var stop := joint.get_node_or_null("End") as Node3D
		if stop == null:
			return ""
		n += 1
		joint = stop.get_node_or_null("J%d" % n) as Node3D
		if joint == null:
			# An End with nothing after it is the tip. Fine.
			return ""
	return ""


## Print the complaint, plus what was done about it.
##
## Saying what happened INSTEAD is half the value: without it the
## operator knows something is wrong but not whether the game survived,
## and a young operator will reasonably assume they destroyed it.
static func _say(broken: String, problem: String, used: String) -> void:
	_last_message = ("[PART] %s — %s\n       Using %s instead, so the game "
			% [broken.get_file(), problem, used.get_file()]
			+ "keeps running. Your file is untouched.")
	print(_last_message)


## Give every block in a loaded part its own collision.
##
## Called after loading so the operator never has to add a collider by
## hand — six fiddly steps per block is exactly the chore that makes a
## tool stop being used. Returns the areas created, for the caller to
## keep.
##
## An Area3D rather than a solid body, carried over from the code-built
## claw: a prong is dragged about by an animated chain, and a solid body
## dragged through the world by an animation fights the physics solver
## instead of obeying it. An area DETECTS what it has closed around,
## which is what a claw actually needs to know.
##
## `monitorable = false` is also what satisfies the neighbour rule
## structurally. Two blocks sharing a joint always overlap — by
## construction, every frame, for ever — and that is what threw the
## spider's skeleton 335 m across the map when it was left unhandled
## (STO-ENEMIES-055). Areas nobody can see cannot notice or shove each
## other, and Area3D has no `add_collision_exception_with` to use
## instead.
static func add_collision(root: Node3D) -> Array:
	var made: Array = []
	_collide(root, made)
	return made


static func _collide(node: Node, made: Array) -> void:
	for child in node.get_children():
		_collide(child, made)

	if not (node is MeshInstance3D):
		return
	var mesh := (node as MeshInstance3D).mesh
	if mesh == null:
		return
	var holder := node.get_parent()
	if holder == null:
		return

	# Respect collision the operator authored by hand rather than
	# doubling it.
	for sibling in holder.get_children():
		if sibling is Area3D or sibling is CollisionShape3D:
			return

	var shape := _shape_for(mesh)
	if shape == null:
		return

	var sense := Area3D.new()
	sense.name = "Touch"
	sense.monitorable = false
	var cs := CollisionShape3D.new()
	cs.shape = shape
	# Match the block exactly — position, angle and all. A collider that
	# merely sits at the same spot goes wrong the moment a block is
	# turned, and turning blocks is the whole point of modelling.
	cs.transform = (node as MeshInstance3D).transform
	sense.add_child(cs)
	holder.add_child(sense)
	made.append(sense)


## A collision shape matching a mesh, or null if the mesh is a kind
## nothing here knows how to wrap yet.
static func _shape_for(mesh: Mesh) -> Shape3D:
	if mesh is BoxMesh:
		var box := BoxShape3D.new()
		box.size = (mesh as BoxMesh).size
		return box
	if mesh is SphereMesh:
		var ball := SphereShape3D.new()
		ball.radius = (mesh as SphereMesh).radius
		return ball
	if mesh is CylinderMesh:
		var cyl := CylinderShape3D.new()
		cyl.height = (mesh as CylinderMesh).height
		cyl.radius = maxf((mesh as CylinderMesh).top_radius,
				(mesh as CylinderMesh).bottom_radius)
		return cyl
	if mesh is CapsuleMesh:
		var cap := CapsuleShape3D.new()
		cap.height = (mesh as CapsuleMesh).height
		cap.radius = (mesh as CapsuleMesh).radius
		return cap
	return null
