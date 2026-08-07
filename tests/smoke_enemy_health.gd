extends SceneTree
## Headless smoke test for STO-ENEMIES-002 (enemies have health).
## Run with:  godot --headless -s res://tests/smoke_enemy_health.gd
##
## Verifies enemies have health, take_damage lowers it, and lethal damage
## defeats (frees) them. (The punch/ram integration is covered by
## smoke_punch.)

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _e_dying: Node


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	var enemies := _main.get_node_or_null("Enemies")
	if enemies == null or enemies.get_child_count() == 0:
		_fail("no enemies")
		return false
	var e0 := enemies.get_child(0) as CharacterBody3D
	if e0.max_health() > 0.0 and is_equal_approx(e0.health(), e0.max_health()):
		_pass("enemies start with full health (%.0f)" % e0.max_health())
	else:
		_fail("enemy health wrong")
	e0.take_damage(20.0)
	if e0.health() < e0.max_health():
		_pass("take_damage lowers enemy health (%.0f)" % e0.health())
	else:
		_fail("take_damage did nothing")
	e0.take_damage(1000.0)  # lethal
	_e_dying = e0
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "check"
		"check":
			_frames += 1
			if _frames >= 3:
				if not is_instance_valid(_e_dying):
					_pass("lethal damage defeats (removes) the enemy")
				else:
					_fail("enemy survived lethal damage")
				return _done()
	return false


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
