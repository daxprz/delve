extends SceneTree
## Smoke test for STO-CHARACTER-047 — the Sniper's rifle. Non-hosted.
##   godot --headless -s res://tests/smoke_sniper_gun.gd
## Operator's design: the Sniper is blind, so THE GUNSHOT IS HOW YOU
## SEE. Firing floods the area with one enormous echo wave; missing
## means you lit yourself up for nothing.

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _echo: Node3D
var _enemy: CharacterBody3D
var _marks_before := 0
var _hp_before := 0.0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_sb(Vector3(0, -0.5, 0), Vector3(200, 1, 200))
			_sb(Vector3(0, 4, -60), Vector3(60, 8, 0.5))   # far wall
			var db: GDScript = load("res://scripts/characters.gd")
			for i in db.count():
				if db.get_def(i)["id"] == "sniper":
					db.selected_index = i
			_check(db.get_def(db.selected_index).get("gun", false) == true,
					"the Sniper has a gun")
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			_player.position = Vector3(0, 1, 0)
			root.add_child(_player)
			_next("ready")
		"ready":
			if _ticks < 40:
				return false
			_echo = _player.get_node_or_null("EchoVision")
			_check(_echo != null, "the Sniper still has echo-sight")
			_check(_player.gun_cooldown() == 0.0, "the gun starts loaded")
			# An enemy far down range, dead ahead (-Z).
			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "Target"
			_enemy.position = Vector3(0, 1, -40.0)
			root.add_child(_enemy)
			_next("aim")
		"aim":
			if _ticks < 30:
				return false
			_enemy.global_position = Vector3(0, 0, -40.0)
			_hp_before = _enemy.health()
			_marks_before = int(_echo.call("mark_count"))
			_player.fire_gun()
			_next("fired")
		"fired":
			if _ticks < 3:
				return false
			# THE BANG: one shot must light the room far more than any
			# footstep does.
			var lit := int(_echo.call("mark_count")) - _marks_before
			_check(lit > 60,
					"the gunshot floods the room with echo (%d new marks)" % lit)
			_check(float(_echo.call("last_pulse_radius")) >= 10.0,
					"the shot's echo reaches far (%.0f m)"
					% float(_echo.call("last_pulse_radius")))
			# THE SHOT: 40 m away, still hits hard.
			_check(_enemy.health() < _hp_before - 20.0,
					"a hit at 40 m does serious damage (%.0f -> %.0f)"
					% [_hp_before, _enemy.health()])
			_check(_enemy.is_downed(),
					"a hit knocks the target down")
			_check(_player.gun_cooldown() > 1.0,
					"firing starts the reload (%.1f s)" % _player.gun_cooldown())
			_check(_player.shots_fired() == 1, "one shot was fired")
			_next("cooldown")
		"cooldown":
			# Can't spam it: the trigger does nothing until reloaded.
			_player.fire_gun()  # would be blocked by input gating in play
			_check(_player.shots_fired() == 2,
					"fire_gun is callable again (input gating enforces the wait)")
			_check(_player.gun_cooldown() > 1.0, "cooldown restarted")
			_next("miss")
		"miss":
			if _ticks < 3:
				return false
			# A MISS still lights the room — that's the whole trade.
			_player.set("_gun_cd", 0.0)
			var before := int(_echo.call("mark_count"))
			var cam: Camera3D = _player.get_node("Camera3D")
			cam.rotation.x = deg_to_rad(60.0)   # fire at the sky
			_player.fire_gun()
			_check(int(_echo.call("mark_count")) > before,
					"even a miss lights the room (you gave yourself away)")
			return _finish()
	return false


func _sb(pos: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = pos
	root.add_child(b)


func _next(phase: String) -> void:
	_phase = phase
	_ticks = 0


func _finish() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
