extends SceneTree
## Headless smoke test for EPI-CHARACTER-ABILITY-KIT — the Grabber kit plus
## the universal heal. Run with:
##   godot --headless -s res://tests/smoke_abilities.gd
##
## Covers: block (damage reduction), parry (shove), throw (grab+hurl),
## pull (yank toward you), grapple-zip (dash to a point), heal-over-time.
##
## Each phase does its action ONCE (guarded by `_frames == 0`) then waits a
## couple of frames before checking. Enemies not in use are parked far away
## so `_nearest_enemy` is deterministic.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _enemies: Node
var _hp := 0.0


func _enemy(i: int) -> CharacterBody3D:
	if _enemies == null or i >= _enemies.get_child_count():
		return null
	return _enemies.get_child(i) as CharacterBody3D


func _park_all() -> void:
	for i in _enemies.get_child_count():
		var e := _enemies.get_child(i) as Node3D
		if e != null:
			# A ragdolling enemy's position is driven by its pelvis, so
			# it would snap straight back next to the player and steal
			# the next ability's targeting. Stand it up first.
			if e.has_method("recover"):
				e.call("recover")
			e.global_position = Vector3(300.0 + i * 6.0, 1.0, 300.0)
			(e as CharacterBody3D).velocity = Vector3.ZERO


func _setup() -> bool:
	CharacterDB.selected_index = 0  # Grabber (has the kit)
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_main.start_game()   # the lobby no longer starts the game for you
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	_enemies = _main.get_node_or_null("Enemies")
	if _player == null or _enemies == null or _enemies.get_child_count() < 3:
		_fail("missing player or <3 enemies")
		return false
	if _player.character_id() != "grabber":
		_fail("expected grabber")
		return false
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_player.velocity = Vector3.ZERO
	_park_all()
	return true


func _physics_process(_delta: float) -> bool:
	_frames += 1
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_to("block_press")
		"block_press":
			if _frames == 1:
				Input.action_press("ability_guard")
			if _frames >= 3:
				_player.set_health(100.0)
				_hp = _player.health()
				_player.take_damage(40.0)  # blocking is active -> reduced
				var lost: float = _hp - _player.health()
				if lost > 5.0 and lost < 15.0:
					_pass("blocking cut 40 damage down to %.0f" % lost)
				else:
					_fail("block did not reduce damage (lost %.0f)" % lost)
				Input.action_release("ability_guard")
				_player.set_health(140.0)
				_to("parry")
		"parry":
			var e := _enemy(0)
			if _frames == 1:
				e.global_position = _player.global_position + Vector3(0, 0, -2.0)
				e.velocity = Vector3.ZERO
				_player.do_parry()
			if _frames >= 3:
				if _launched(e, -4.0) or e.global_position.z < -2.5:
					_pass("parry shoved the enemy away")
				else:
					_fail("parry did not shove (vz %.1f)" % e.velocity.z)
				_park_all()
				_to("throw_grab")
		"throw_grab":
			var e := _enemy(1)
			if _frames == 1:
				e.global_position = _player.global_position + Vector3(0, 0, -2.0)
				e.velocity = Vector3.ZERO
				_player.do_throw()  # grab
			if _frames >= 3:
				if _player.held_object() == e:
					_pass("throw grabbed the enemy (holding it)")
				else:
					_fail("throw did not grab (held %s)" % str(_player.held_object()))
				_to("throw_release")
		"throw_release":
			var e := _enemy(1)
			if _frames == 1:
				_player.do_throw()  # hurl it forward (-Z)
			if _frames >= 3:
				var gone := not is_instance_valid(e)
				if gone or (_player.held_object() == null and _launched(e, -8.0)):
					_pass("throw hurled the enemy forward (%s)"
							% ("gone" if gone else "vz %.0f" % e.velocity.z))
				else:
					_fail("throw did not hurl (held %s)" % str(_player.held_object()))
				_park_all()
				_to("pull")
		"pull":
			var e := _enemy(2)
			if _frames == 1:
				e.global_position = _player.global_position + Vector3(0, 0, -8.0)
				e.velocity = Vector3.ZERO
				_player.do_pull()
			if _frames >= 3:
				if _launched(e, 5.0):
					_pass("pull yanked the enemy toward you")
				else:
					_fail("pull did not yank (vz %.1f)" % e.velocity.z)
				_to("zip")
		"zip":
			if _frames == 1:
				_player.global_position = Vector3(40.0, 2.0, 40.0)
				_player.velocity = Vector3.ZERO
				_player.test_zip(Vector3(40.0, 1.0, 30.0))
			if _frames >= 40:
				var z := _player.global_position.z
				if z < 36.0 and not _player.is_zipping():
					_pass("grapple-zip dashed to the point (z %.1f)" % z)
				else:
					_fail("zip did not arrive (z %.1f, zipping %s)"
							% [z, str(_player.is_zipping())])
				_player.global_position = Vector3(40.0, 1.0, 40.0)
				_player.set_health(70.0)
				_hp = _player.health()
				_to("heal")
		"heal":
			_player.global_position = Vector3(40.0, 1.0, 40.0)
			if _frames >= 100:
				if _player.health() > _hp + 2.0:
					_pass("heal-over-time regenerated (%.0f -> %.0f)"
							% [_hp, _player.health()])
				else:
					_fail("no heal-over-time (%.0f -> %.0f)" % [_hp, _player.health()])
				return _done()
	return false


func _to(phase: String) -> void:
	_phase = phase
	_frames = 0


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true

func _pass(msg: String) -> void:
	print("PASS: %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)


## Did an ability actually launch this enemy in direction `want_vz`?
##
## Enemies ragdoll on strong hits now (STO-ENEMIES-006), and a
## ragdolling enemy's own `velocity` is always zero — the momentum is
## carried by its physics parts. So accept EITHER a body-velocity
## change or a ragdoll whose pelvis is genuinely moving that way.
## Being ragdolled alone is NOT enough: it must be in motion, so an
## ability that does nothing still fails.
func _launched(e, want_vz: float) -> bool:
	if not is_instance_valid(e):
		return true          # defeated outright
	if (want_vz < 0.0 and e.velocity.z < want_vz) \
			or (want_vz > 0.0 and e.velocity.z > want_vz):
		return true
	if e.has_method("ragdoll"):
		var rag = e.call("ragdoll")
		if rag != null:
			var pelvis: RigidBody3D = rag.call("part", "Pelvis")
			if pelvis != null:
				var vz := pelvis.linear_velocity.z
				# launch() gives parts ~0.8x the hit, so allow for that.
				return (want_vz < 0.0 and vz < want_vz * 0.6) \
						or (want_vz > 0.0 and vz > want_vz * 0.6)
	return false
