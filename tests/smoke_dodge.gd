extends SceneTree
## Headless smoke test for STO-CHARACTER-030 (Runner dodge roll).
## Run with:  godot --headless -s res://tests/smoke_dodge.gd
##
## The Runner rolls fast in the facing direction and is INVINCIBLE while
## rolling; once the roll ends, damage lands normally again.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _z0 := 0.0
var _hp := 0.0


func _setup() -> bool:
	CharacterDB.selected_index = 1  # Runner (has dodge)
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null or _player.character_id() != "runner":
		_fail("missing Runner")
		return false
	_player.global_position = Vector3(40.0, 1.0, 40.0)
	_player.velocity = Vector3.ZERO
	_player.set_health(80.0)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "roll_start"
		"roll_start":
			_z0 = _player.global_position.z
			_hp = _player.health()
			_player.do_dodge()  # faces -Z by default
			if not _player.is_rolling():
				_fail("dodge did not start rolling")
				return _done()
			# Take a big hit mid-roll — should be ignored (invincible).
			_player.take_damage(50.0)
			_frames = 0
			_phase = "roll_mid"
		"roll_mid":
			_frames += 1
			if _frames == 1:
				if is_equal_approx(_player.health(), _hp):
					_pass("invincible during the roll (no damage taken)")
				else:
					_fail("took damage mid-roll (%.0f -> %.0f)" % [_hp, _player.health()])
			if _frames >= 40:
				var moved := _z0 - _player.global_position.z
				if not _player.is_rolling() and moved > 2.0:
					_pass("roll ended after moving fast (%.1f m)" % moved)
				else:
					_fail("roll wrong (moved %.1f, rolling %s)"
							% [moved, str(_player.is_rolling())])
				_hp = _player.health()
				_frames = 0
				_phase = "after"
		"after":
			_frames += 1
			if _frames >= 2:
				# No longer rolling: damage should land normally now.
				_player.take_damage(20.0)
				if _player.health() < _hp - 1.0:
					_pass("damage lands normally after the roll")
				else:
					_fail("still invincible after the roll")
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
