extends SceneTree
## Headless smoke test for STO-WORLD-004 (procedural maze map).
## Run with:  godot --headless -s res://tests/smoke_procmap.gd
##
## Verifies the map is really procedural (different seeds -> different
## layouts; same seed -> same layout), has plenty of walls + climb
## features, and is a SEPARATE node from the playground/testing.

const ProcMapScript := preload("res://scripts/procmap.gd")

var _failures := 0
var _done_flag := false


func _physics_process(_delta: float) -> bool:
	if _done_flag:
		return true
	_done_flag = true
	_run()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _make(seed_val: int):
	var m: Node = ProcMapScript.new()
	m.set("map_seed", seed_val)
	root.add_child(m)
	return m


func _run() -> void:
	var a = _make(1)
	var b = _make(2)
	var a2 = _make(1)

	if a.wall_count() > 20 and a.upper_count() >= 3:
		_pass("map built %d walls (rooms) + %d upper areas"
				% [a.wall_count(), a.upper_count()])
	else:
		_fail("map too sparse (walls=%d upper=%d)" % [a.wall_count(), a.upper_count()])

	if a.layout_hash() != b.layout_hash():
		_pass("different seeds give different layouts (procedural)")
	else:
		_fail("seeds 1 and 2 gave the same layout")

	if a.layout_hash() == a2.layout_hash():
		_pass("the same seed regenerates the same layout (deterministic)")
	else:
		_fail("same seed gave a different layout")

	a.free()
	b.free()
	a2.free()

	# Separate from the testing playground.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var pm := main.get_node_or_null("ProcMap")
	var pg := main.get_node_or_null("Playground")
	if pm != null and pg != null and (pm as Node3D).position != Vector3.ZERO:
		_pass("procedural map is its own node, placed apart from the playground")
	else:
		_fail("procmap/playground not separate (procmap=%s playground=%s)"
				% [pm != null, pg != null])


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
