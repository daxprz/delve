extends SceneTree
## Headless smoke test for STO-COMBAT-003 (combo meter).
## Run with:  godot --headless -s res://tests/smoke_combo.gd
##
## Verifies chained hits build a combo that multiplies damage, and that
## the combo resets after a while with no hits.

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _enemy: CharacterBody3D


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false
	_enemy = enemies.get_child(0) as CharacterBody3D
	_enemy.set_physics_process(false)
	# Keep the player on the floor so there's no air bonus muddying the math.
	_player.global_position = Vector3(0.0, 0.0, 0.0)
	_player.set_physics_process(false)

	# Two equal hits: the second should hurt MORE (combo multiplier).
	var hp0: float = _enemy.health()
	_player.deal_damage(_enemy, 10.0)
	var hp1: float = _enemy.health()
	var d1 := hp0 - hp1
	_player.deal_damage(_enemy, 10.0)
	var hp2: float = _enemy.health()
	var d2 := hp1 - hp2
	if d2 > d1 + 0.5:
		_pass("chained hits do more damage (%.1f then %.1f)" % [d1, d2])
	else:
		_fail("combo did not multiply (%.1f then %.1f)" % [d1, d2])
	if _player.combo() >= 2:
		_pass("combo counter climbs (%d)" % _player.combo())
	else:
		_fail("combo did not climb (%d)" % _player.combo())
	# Re-enable processing so the combo timer can tick down.
	_player.set_physics_process(true)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "wait"
		"wait":
			_frames += 1
			if _frames >= 140:  # > COMBO_WINDOW (2s)
				if _player.combo() == 0:
					_pass("combo resets after no hits for a while")
				else:
					_fail("combo did not reset (%d)" % _player.combo())
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
