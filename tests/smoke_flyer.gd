extends SceneTree
## Headless smoke test for EPI-CHARACTER-FLYER-CHARACTER
## (STO-CHARACTER-022/023/024). Run with:
##   godot --headless -s res://tests/smoke_flyer.gd
##
## Verifies the Flyer: has wings (no arms/tail), flies up while flapping
## (draining fuel), falls when out of fuel, dive-bombs with Shift, and can
## grab an enemy and drop it to (fall-)damage it.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _enemy: CharacterBody3D
var _y0 := 0.0
var _fuel0 := 0.0
var _enemy_hp0 := 0.0


func _setup() -> bool:
	CharacterDB.selected_index = 2  # Flyer
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false

	if _player.character_id() == "flyer" \
			and _player.get_node_or_null("Wings") != null \
			and _player.get_node_or_null("MechanicalArms") == null \
			and _player.get_node_or_null("Tail") == null:
		_pass("Flyer spawned with wings (no arms/tail)")
	else:
		_fail("Flyer setup wrong")

	_enemy = enemies.get_child(0) as CharacterBody3D
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_start_ascend()
		"ascend":
			_frames += 1
			if _frames >= 25:
				var climbed := _player.global_position.y - _y0
				if climbed > 0.5 and _player.fly_fuel() < _fuel0:
					_pass("flapping flies up (%.1f m) and drains fuel (%.1f->%.1f)"
							% [climbed, _fuel0, _player.fly_fuel()])
				else:
					_fail("flight failed (climbed %.1f, fuel %.1f)"
							% [climbed, _player.fly_fuel()])
				_start_nofuel()
		"nofuel":
			_frames += 1
			if _frames >= 20:
				if _player.global_position.y < _y0 - 0.5:
					_pass("out of fuel, the Flyer falls")
				else:
					_fail("no-fuel Flyer did not fall (y %.1f)" % _player.global_position.y)
				_start_dive()
		"dive":
			_frames += 1
			if _frames >= 6:
				if _player.velocity.y < -10.0:
					_pass("Shift dive-bombs downward (vy %.1f)" % _player.velocity.y)
				else:
					_fail("dive did not go down (vy %.1f)" % _player.velocity.y)
				Input.action_release("sprint")
				_start_carry()
		"carry":
			# Grabbed the enemy; carry it up high, then drop it.
			_frames += 1
			_player.global_position = Vector3(0.0, 16.0, 0.0)
			_player.velocity = Vector3.ZERO
			if _frames == 2:
				if _player.carried_enemy() != null:
					_pass("LMB+RMB grabbed an enemy (carried)")
				else:
					_fail("did not grab an enemy")
			if _frames >= 8:
				_enemy_hp0 = _enemy.health() if is_instance_valid(_enemy) else 0.0
				_player.test_carry(false)  # DROP
				# Fly far away and let the dropped enemy free-fall from height.
				_player.global_position = Vector3(50.0, 1.0, 50.0)
				_enemy.global_position = Vector3(5.0, 20.0, 5.0)
				_frames = 0
				_phase = "dropped"
		"dropped":
			_player.global_position = Vector3(50.0, 1.0, 50.0)
			_frames += 1
			if _frames >= 150:
				var hurt: bool = (not is_instance_valid(_enemy)) or (_enemy.health() < _enemy_hp0 - 1.0)
				if hurt:
					_pass("dropping the enemy from height hurt/killed it")
				else:
					_fail("dropped enemy took no fall damage (%.0f)" % _enemy.health())
				return _done()
	return false


func _start_ascend() -> void:
	_player.global_position = Vector3(0.0, 12.0, 0.0)
	_player.velocity = Vector3.ZERO
	_player.set_fuel(5.0)
	_y0 = _player.global_position.y
	_fuel0 = _player.fly_fuel()
	Input.action_press("jump")
	_frames = 0
	_phase = "ascend"


func _start_nofuel() -> void:
	Input.action_release("jump")
	_player.global_position = Vector3(0.0, 12.0, 0.0)
	_player.velocity = Vector3.ZERO
	_player.set_fuel(0.0)
	_y0 = _player.global_position.y
	Input.action_press("jump")
	_frames = 0
	_phase = "nofuel"


func _start_dive() -> void:
	Input.action_release("jump")
	_player.global_position = Vector3(0.0, 12.0, 0.0)
	_player.velocity = Vector3.ZERO
	_player.set_fuel(5.0)
	Input.action_press("sprint")  # Shift
	_frames = 0
	_phase = "dive"


func _start_carry() -> void:
	_player.global_position = Vector3(0.0, 2.0, 0.0)
	_player.set_fuel(5.0)
	_enemy.global_position = Vector3(0.5, 1.0, 0.0)  # within grab range
	_player.test_carry(true)
	_frames = 0
	_phase = "carry"


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
