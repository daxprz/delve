extends SceneTree
## Smoke test for STO-CHARACTER-048 — the Sniper's RMB lidar. Non-hosted.
##   godot --headless -s res://tests/smoke_lidar.gd
## A scan paints what's AHEAD, HOLDS it for a few seconds, then fades.
## That's what separates it from a footstep ripple (a passing glimpse)
## and the rifle (one huge flash that announces you).

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _echo: Node3D
var _cam: Camera3D
var _lit_early := 0
var _behind_marks := 0
var _ahead_marks := 0
var _enemy: CharacterBody3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_sb(Vector3(0, -0.5, 0), Vector3(200, 1, 200))
			_sb(Vector3(0, 4, -25), Vector3(60, 8, 0.5))   # wall AHEAD (-Z)
			_sb(Vector3(0, 4, 25), Vector3(60, 8, 0.5))    # wall BEHIND (+Z)
			var db: GDScript = load("res://scripts/characters.gd")
			for i in db.count():
				if db.get_def(i)["id"] == "sniper":
					db.selected_index = i
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			_player.position = Vector3(0, 1, 0)
			root.add_child(_player)
			_next("ready")
		"ready":
			if _ticks < 40:
				return false
			_echo = _player.get_node("EchoVision")
			_cam = _player.get_node("Camera3D")
			_check(_player.scan_cooldown() == 0.0, "the lidar starts ready")
			# Face the far wall (-Z) and scan.
			_player.set_physics_process(false)   # stop footstep echoes
			_cam.rotation = Vector3.ZERO
			_player.rotation = Vector3.ZERO
			for p in _echo.get("_pulses_live"):
				pass
			_echo.set("_pulses_live", [])         # clean slate
			_player.lidar_scan()
			_check(_player.scans_done() == 1, "a scan was emitted")
			_check(_player.scan_cooldown() > 1.0,
					"scanning starts a cooldown (%.1f s)"
					% _player.scan_cooldown())
			_next("sweeping")
		"sweeping":
			# The sweep travels: far points are NOT lit immediately.
			if _ticks == 2:
				_lit_early = _lit(0.9)
			if _ticks < 90:
				return false
			# By now the sweep has crossed the room and is holding.
			var lit_now := _lit(0.9)
			_check(lit_now > _lit_early,
					"the scan sweeps outward, lighting more over time (%d -> %d)"
					% [_lit_early, lit_now])
			_check(lit_now > 40,
					"the scan paints a lot of the room ahead (%d points)" % lit_now)
			# It is DIRECTIONAL: points ahead, nothing behind.
			for m in _echo.call("all_marks"):
				if (m["pos"] as Vector3).z < -5.0:
					_ahead_marks += 1
				elif (m["pos"] as Vector3).z > 5.0:
					_behind_marks += 1
			_check(_ahead_marks > 20,
					"the scan hits the wall we're facing (%d)" % _ahead_marks)
			_check(_behind_marks == 0,
					"the scan sees nothing behind us (%d)" % _behind_marks)
			_next("enemies_red")
		"enemies_red":
			if _ticks == 1:
				# Put an enemy in the scan cone.
				var es: GDScript = load("res://scripts/enemy.gd")
				_enemy = es.new()
				_enemy.name = "Contact"
				_enemy.position = Vector3(0, 1, -12.0)
				root.add_child(_enemy)
				return false
			if _ticks == 10:
				# Only NOW sweep: a body added this tick is not in the
				# physics space yet, so a same-tick ray sails through it.
				_enemy.set_physics_process(false)   # keep it put
				_echo.set("_pulses_live", [])
				_player.set("_scan_cd", 0.0)
				_player.lidar_scan()
			if _ticks < 80:
				return false
			var reds := int(_echo.call("enemy_mark_count"))
			_check(reds > 0, "the lidar paints the enemy RED (%d marks)" % reds)
			# Those red marks must actually be ON the enemy.
			var on_target := 0
			for m in _echo.call("all_marks"):
				if not bool(m.get("enemy", false)):
					continue
				if (m["pos"] as Vector3).distance_to(
						_enemy.global_position + Vector3(0, 0.9, 0)) < 1.6:
					on_target += 1
			_check(on_target == reds,
					"every red mark is on the enemy (%d of %d)" % [on_target, reds])
			# Walls in the same scan stay blue.
			var blues := int(_echo.call("mark_count")) - reds
			_check(blues > 20, "the room is still painted blue (%d)" % blues)
			# And passive hearing must STILL never reveal a creature.
			_echo.set("_pulses_live", [])
			_echo.call("emit_pulse", Vector3(0, 1, -12.0), 5.0, _enemy)
			_check(int(_echo.call("enemy_mark_count")) == 0,
					"footstep echoes still never show a creature")
			_next("holding")
		"holding":
			if _ticks == 1:
				_echo.set("_pulses_live", [])
				_player.set("_scan_cd", 0.0)
				_player.lidar_scan()
				return false
			# Still lit ~2 s after the sweep passed: it HOLDS.
			if _ticks < 120:
				return false
			_check(_lit(0.9) > 40,
					"the scan is still holding a couple of seconds later (%d)"
					% _lit(0.9))
			_next("fading")
		"fading":
			# ...and then it goes away. The farthest points are painted
			# last and hold longest, so wait for the whole scan rather
			# than guessing a tick count.
			# Wait for the whole scan to die rather than guessing ticks:
			# the farthest points are painted last and hold longest.
			if int(_echo.call("live_wave_count")) > 0 or _lit(0.05) > 0:
				if _ticks > 800:
					_check(false, "the scan never faded (%d lit)" % _lit(0.05))
					return _finish()
				return false
			_check(true, "the scan fades away and is discarded")
			return _finish()
	return false


## How many scan points are currently at least `threshold` bright.
func _lit(threshold: float) -> int:
	var n := 0
	for p in _echo.get("_pulses_live"):
		var elapsed: float = float(Time.get_ticks_msec() - int(p["born"])) / 1000.0
		var linger: float = float(p.get("linger", 0.0))
		if linger <= 0.0:
			continue
		for m in p["marks"]:
			if float(_echo.call("_scan_brightness", float(m["dist"]),
					elapsed, linger)) >= threshold:
				n += 1
	return n


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
