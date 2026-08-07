extends SceneTree
## Headless smoke test for punch mode as a RAM (STO-CHARACTER-021).
## Run with:  godot --headless -s res://tests/smoke_punch.gd
##
## Verifies:
##   - E toggles grab/punch; punch mode drops any grab
##   - holding the button sticks the fist out (extended)
##   - ramming an extended fist into an enemy WITH momentum damages it;
##     no momentum = no damage; enough momentum makes a shockwave

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _enemy: CharacterBody3D
var _hp_slow := 0.0
var _sw_slow := 0


func _setup() -> bool:
	CharacterDB.selected_index = 0  # Grabber
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no arms")
		return false

	# Mode toggle + drop grab.
	if not _arms.is_punch_mode():
		_pass("starts in grab mode")
	else:
		_fail("did not start in grab mode")
	_arms.grab(0, _player.global_position + Vector3(0, 1, -1))
	_arms.set_punch_mode(true)
	if _arms.is_punch_mode() and not _arms.is_grabbed(0):
		_pass("E->punch mode drops the grab")
	else:
		_fail("punch mode did not clear the grab")

	_player.set_physics_process(false)
	_player.rotation = Vector3.ZERO
	_arms.set_extended(0, true)   # stick the left fist out
	if _arms.is_extended(0):
		_pass("holding the button sticks the fist out")
	else:
		_fail("fist did not extend")
	_enemy = enemies.get_child(0) as CharacterBody3D
	_enemy.set_physics_process(false)
	return true


func _place_enemy_at_fist() -> void:
	if not is_instance_valid(_enemy):
		return
	var fist: Vector3 = _arms.hand_point(0)
	_enemy.global_position = fist - Vector3(0.0, 0.8, 0.0)  # centre on the fist


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "reach"
		"reach":
			# Let the fist reach out, then park the enemy on it.
			_frames += 1
			if _frames >= 20:
				_place_enemy_at_fist()
				_frames = 0
				_phase = "slow"
		"slow":
			# Barely moving: an extended fist should do (almost) no damage.
			_player.velocity = Vector3(0.0, 0.0, -1.0)
			_place_enemy_at_fist()
			_frames += 1
			if _frames >= 30:
				_hp_slow = _enemy.health()
				_sw_slow = _arms.shockwaves_spawned()
				if _hp_slow > _enemy.max_health() - 1.0:
					_pass("no momentum => the ram does no damage")
				else:
					_fail("slow ram still damaged the enemy (%.0f)" % _hp_slow)
				_frames = 0
				_phase = "fast"
		"fast":
			# Lots of momentum: the ram hits hard and makes a shockwave.
			_player.velocity = Vector3(0.0, 0.0, -12.0)
			_place_enemy_at_fist()
			_frames += 1
			if _frames >= 30:
				var defeated := not is_instance_valid(_enemy)
				if defeated or _enemy.health() < _hp_slow - 1.0:
					_pass("momentum ram damages the enemy (%s)"
							% ("defeated it!" if defeated else "%.0f -> %.0f" % [_hp_slow, _enemy.health()]))
				else:
					_fail("fast ram did no damage (%.0f)" % _enemy.health())
				if _arms.shockwaves_spawned() > _sw_slow:
					_pass("a fast ram makes a shockwave")
				else:
					_fail("no shockwave from a fast ram")
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
