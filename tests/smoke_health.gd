extends SceneTree
## Headless smoke test for EPI-COMBAT-HEALTH (STO-COMBAT-001/002).
## Run with:  godot --headless -s res://tests/smoke_health.gd
##
## Verifies:
##   - Grabber has more max health than the Runner; players start full
##   - taking damage lowers health; dropping to 0 respawns at full health
##   - an enemy that reaches the player damages it (STO-ENEMIES-011)

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _hp_before := 0.0


func _setup() -> bool:
	# --- Per-character health (direct instances) ---
	CharacterDB.selected_index = 0
	var g: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(g)
	var g_max: float = g.max_health()
	var full_ok: bool = is_equal_approx(g.health(), g_max)
	g.take_damage(30.0)
	var dmg_ok: bool = g.health() < g_max
	g.take_damage(g_max * 2.0)  # lethal
	var respawn_ok: bool = is_equal_approx(g.health(), g_max)
	g.free()

	CharacterDB.selected_index = 1
	var r: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(r)
	var r_max: float = r.max_health()
	r.free()

	if g_max > r_max:
		_pass("Grabber has more health than the Runner (%.0f > %.0f)" % [g_max, r_max])
	else:
		_fail("Grabber not tougher (%.0f vs %.0f)" % [g_max, r_max])
	if full_ok:
		_pass("players start at full health")
	else:
		_fail("players did not start full")
	if dmg_ok:
		_pass("taking damage lowers health")
	else:
		_fail("damage did not lower health")
	if respawn_ok:
		_pass("dying respawns at full health")
	else:
		_fail("did not respawn at full health")

	# --- Enemy contact damage ---
	CharacterDB.selected_index = 0
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	var enemies := _main.get_node_or_null("Enemies")
	if _player == null or enemies == null or enemies.get_child_count() == 0:
		_fail("missing player or enemies")
		return false
	var enemy := enemies.get_child(0) as CharacterBody3D
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	enemy.global_position = Vector3(1.0, 1.0, 0.0)  # right next to the player
	_hp_before = _player.health()
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "fight"
		"fight":
			_frames += 1
			if _frames >= 200:   # long enough to close in AND wind up
				# INVERTED for STO-ENEMIES-011. This used to assert
				# "an enemy touching the player does NO damage",
				# because until then enemy.gd said in as many words
				# that enemies only chase. The operator asked for
				# enemies that fight back, so the requirement flipped.
				if _player.health() < _hp_before:
					_pass("an enemy that reaches the player damages it (%.0f -> %.0f)"
							% [_hp_before, _player.health()])
				else:
					_fail("the enemy never landed a blow (%.0f)"
							% _player.health())
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
