extends SceneTree
## Headless smoke test for chain-vs-world collision (STO-CHARACTER-011).
## Run with:  godot --headless -s res://tests/smoke_chain_collision.gd
##
## Puts a solid shelf under the Grabber and checks the arms REST ON the
## shelf instead of hanging straight through it to the floor — i.e. the
## arms collide with geometry, not just the ground.

const SETTLE := 90

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _shelf_y := 1.2


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no arms")
		return false

	# A wide solid shelf just below shoulder height, right under the player.
	var shelf := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 0.3, 6.0)
	shape.shape = box
	shelf.add_child(shape)
	_main.add_child(shelf)
	shelf.global_position = Vector3(_player.global_position.x, _shelf_y,
			_player.global_position.z)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "settle"
		"settle":
			_frames += 1
			if _frames >= SETTLE:
				_check_rest()
				return _done()
	return false


func _check_rest() -> void:
	# With floor-only collision the hands would fall to ~0.06 (the ground).
	# Resting on the shelf, they should stay up near the shelf top.
	var h0: Vector3 = _arms.hand_point(0)
	var h1: Vector3 = _arms.hand_point(1)
	var lowest := minf(h0.y, h1.y)
	if lowest > _shelf_y - 0.4:
		_pass("arms rest on the shelf (lowest hand y=%.2f, shelf=%.2f)"
				% [lowest, _shelf_y])
	else:
		_fail("arms fell through the shelf to the floor (lowest hand y=%.2f)"
				% lowest)


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
