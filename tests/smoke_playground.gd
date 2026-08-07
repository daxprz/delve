extends SceneTree
## Headless smoke test for EPI-WORLD-PLAYGROUND (STO-WORLD-001/002).
## Run with:  godot --headless -s res://tests/smoke_playground.gd
##
## Verifies:
##   - the Playground built a MovableBox (RigidBody3D), a Wall, and
##     several Pillars (all StaticBody3D)
##   - the pillars are at stepped (different) heights
##   - walking the player into the box actually pushes it (it moves)
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const SETTLE := 30
const PUSH := 50

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _box: RigidBody3D
var _box_start := Vector3.ZERO


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)

	var pg := _main.get_node_or_null("Playground")
	if pg == null:
		_fail("no Playground node in main scene")
		return false

	_box = pg.get_node_or_null("MovableBox") as RigidBody3D
	if _box != null:
		_pass("MovableBox is a RigidBody3D")
	else:
		_fail("MovableBox missing or not a RigidBody3D")

	var wall := pg.get_node_or_null("Wall")
	if wall is StaticBody3D:
		_pass("Wall is a StaticBody3D")
	else:
		_fail("Wall missing or not static")

	var pillars := 0
	var heights := {}
	for c in pg.get_children():
		if String(c.name).begins_with("Pillar") and c is StaticBody3D:
			pillars += 1
			var node3d := c as Node3D
			heights[snappedf(node3d.position.y, 0.01)] = true
	if pillars >= 3:
		_pass("built %d pillars" % pillars)
	else:
		_fail("expected >= 3 pillars, got %d" % pillars)
	if heights.size() >= 2:
		_pass("pillars are at %d different heights (stepped)" % heights.size())
	else:
		_fail("pillars are not stepped (distinct heights=%d)" % heights.size())

	# Spawn a player and place it just behind the box, facing it (-Z).
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player to push with")
		return false
	if _box == null:
		return false
	_player.global_position = _box.global_position + Vector3(0.0, 0.0, 1.6)
	_player.rotation = Vector3.ZERO  # facing -Z, toward the box
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_phase = "settle"
		"settle":
			_frames += 1
			if _frames >= SETTLE:
				_box_start = _box.global_position
				Input.action_press("move_forward")
				_frames = 0
				_phase = "push"
		"push":
			_frames += 1
			if _frames >= PUSH:
				Input.action_release("move_forward")
				_check_pushed()
				return _done()
	return false


func _check_pushed() -> void:
	var moved := _box_start.distance_to(_box.global_position)
	if moved > 0.25:
		_pass("player pushed the box %.2f m" % moved)
	else:
		_fail("box did not move when pushed (%.2f m)" % moved)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
