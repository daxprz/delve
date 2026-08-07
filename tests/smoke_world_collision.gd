extends SceneTree
## World-integrity smoke test: every StaticBody3D's visible box mesh
## must sit exactly on its collision box — no editor-nudged meshes
## floating above (or sunk below) their hitboxes. Guards against the
## "grass is higher than the floor's hitbox" class of bug.
##   godot --headless -s res://tests/smoke_world_collision.gd
## Exits 0 on PASS, 1 on FAIL.

const TOLERANCE := 0.02  # metres

var _failures := 0
var _checked := 0
var _main: Node
var _ticks := 0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 5:
		return false  # let procedural builders (_ready) finish

	_sweep(_main)
	print("checked %d static-body box pairs" % _checked)
	if _checked == 0:
		_fail("found no box mesh/shape pairs to check")
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _sweep(n: Node) -> void:
	if n is StaticBody3D:
		_check_body(n)
	for c in n.get_children():
		_sweep(c)


func _check_body(body: StaticBody3D) -> void:
	var mesh: MeshInstance3D
	var shape: CollisionShape3D
	for c in body.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			mesh = c
		elif c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			shape = c
	if mesh == null or shape == null:
		return  # not a box/box body — out of scope
	_checked += 1

	var msize: Vector3 = (mesh.mesh as BoxMesh).size
	var ssize: Vector3 = (shape.shape as BoxShape3D).size
	if (msize - ssize).length() > TOLERANCE:
		_fail("%s: mesh size %s != shape size %s"
				% [body.get_path(), msize, ssize])

	var off := mesh.global_position - shape.global_position
	if off.length() > TOLERANCE:
		_fail("%s: mesh offset from hitbox by %s (|%.3f| m) — visible "
				% [body.get_path(), off, off.length()]
				+ "surface won't match physics")


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
