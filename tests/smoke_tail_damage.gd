extends SceneTree
## Headless smoke test for STO-CHARACTER-020 (tail deals speed-based
## damage). Run with:  godot --headless -s res://tests/smoke_tail_damage.gd
##
## Whips the Runner's tail through an enemy (by moving the player fast)
## and checks the enemy takes damage; a still tail does not.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _enemy: CharacterBody3D
var _hp_before := 0.0
var _still_hp := 0.0


func _setup() -> bool:
	CharacterDB.selected_index = 1  # Runner (has the tail)
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	# Spawn the player directly instead of hosting (STO-TOOLS-009).
	# Nothing here needs a network, and host_game() binds UDP 7777, so
	# this test could not run at all while the operator had the game
	# open — which is how two tests once shipped failing unnoticed.
	var _p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	_p.name = "1"
	_main.get_node("Players").add_child(_p)
	_player = _p
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false
	_player.set_physics_process(false)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_enemy = enemies.get_child(0) as CharacterBody3D
	_enemy.set_physics_process(false)
	# Right under where the tail hangs (base is behind the player at z~0.45).
	_enemy.global_position = Vector3(0.0, 0.0, 0.45)
	_hp_before = _enemy.health()
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "settle"
		"settle":
			# Stand still (no teleporting) and let the tail settle to a stop.
			_player.global_position = Vector3(0.0, 1.0, 0.0)
			_frames += 1
			if _frames >= 60:
				_still_hp = _enemy.health()
				_frames = 0
				_phase = "still"
		"still":
			# A settled (slow) tail resting on the enemy should do no damage.
			_player.global_position = Vector3(0.0, 1.0, 0.0)
			_frames += 1
			if _frames >= 30:
				if is_equal_approx(_enemy.health(), _still_hp):
					_pass("a settled/slow tail does no damage")
				else:
					_fail("slow tail damaged the enemy (%.0f -> %.0f)"
							% [_still_hp, _enemy.health()])
				_still_hp = _enemy.health()
				_frames = 0
				_phase = "whip"
		"whip":
			# Sweep the player fast side-to-side (smoothly from spawn) so the
			# tail whips across the enemy at speed.
			var x := sin(float(_frames) * 0.4) * 2.5
			_player.global_position = Vector3(x, 1.0, 0.0)
			_frames += 1
			var dead := not is_instance_valid(_enemy)
			if dead or _frames >= 120:
				if dead or _enemy.health() < _still_hp - 1.0:
					_pass("a fast-swinging tail damages the enemy (%s)"
							% ("defeated it!" if dead else "%.0f -> %.0f" % [_still_hp, _enemy.health()]))
				else:
					_fail("fast tail did no damage (%.0f)" % _enemy.health())
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
