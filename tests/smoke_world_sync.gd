extends SceneTree
## Regression test for STO-CORE-005/006 — the world must be SHARED.
##   godot --headless -s res://tests/smoke_world_sync.gd
##
## The bug: every instance built its own world in _ready. Enemies were
## created from a script on each machine, so each had a private set
## that only the server ever moved; and the maze seed came from
## randi(), so host and client generated DIFFERENT mazes and could
## walk through walls the other could see.
##
## Two instances can't be run inside one test, so this checks the
## structural guarantees that make sharing possible, and the
## replication itself is verified live with two instances.

var _failures := 0
var _ticks := 0
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 6:
		return false

	# --- enemies are replicable (STO-CORE-005) ---
	var spawner: MultiplayerSpawner = _main.get_node_or_null("EnemySpawner")
	_check(spawner != null, "there is a spawner for enemies")
	if spawner != null:
		_check(spawner.get_spawnable_scene_count() > 0,
				"the enemy scene is registered as spawnable")
		_check(str(spawner.spawn_path).ends_with("Enemies"),
				"it watches the Enemies container (%s)" % str(spawner.spawn_path))

	var enemies := _main.get_node_or_null("Enemies")
	_check(enemies != null and enemies.get_child_count() > 0,
			"enemies exist in that container")
	if enemies != null and enemies.get_child_count() > 0:
		var e := enemies.get_child(0)
		# A script-built node can never replicate; it must come from a
		# scene, and carry a synchronizer for its position.
		_check(e.scene_file_path != "",
				"an enemy is instanced from a scene (%s)" % e.scene_file_path)
		_check(e.get_node_or_null("MultiplayerSynchronizer") != null,
				"an enemy carries a MultiplayerSynchronizer")

	# --- everyone can share one map (STO-CORE-006) ---
	_check(_main.has_method("map_seed"), "the map seed is readable")
	var first: int = _main.call("map_seed")
	_check(first != 0, "a seed was chosen for this session")

	# Rebuilding from a given seed is what lets a client adopt the
	# server's maze instead of its own.
	_main.call("_build_procmap", 12345)
	_check(int(_main.call("map_seed")) == 12345,
			"the map can be rebuilt from a specific seed")
	var pm := _main.get_node_or_null("ProcMap")
	_check(pm != null and int(pm.get("map_seed")) == 12345,
			"the rebuilt maze actually uses it")
	# ...and rebuilding must not leave two mazes stacked in the scene.
	var maps := 0
	for c in _main.get_children():
		if c.name == "ProcMap":
			maps += 1
	_check(maps == 1, "rebuilding replaces the old maze (%d present)" % maps)

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
