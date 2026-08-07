extends SceneTree
## Smoke test for the Sniper's echo-sight (STO-CHARACTER-040/041/043/
## 048/049/050). Replaces the old smoke_sniper_echo + smoke_lidar,
## which tested an expanding-wave model that has been folded into a
## persistent-mark one.
##   godot --headless -s res://tests/smoke_echo_vision.gd
##
## The model now: every reading leaves a MARK on a surface.
##   LIDAR marks are white, last 5 minutes, and a fresh sweep replaces
##   the stale ones near each hit.
##   SOUND marks are red and fade far sooner.
## Both stay dark until the wavefront reaches them, then fade with age.

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _echo: Node3D
var _enemy: CharacterBody3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_sb(Vector3(0, -0.5, 0), Vector3(120, 1, 120))
			_sb(Vector3(0, 4, -20), Vector3(60, 8, 0.5))    # wall ahead
			_sb(Vector3(0, 4, 20), Vector3(60, 8, 0.5))     # wall behind
			var db: GDScript = load("res://scripts/characters.gd")
			for i in db.count():
				if db.get_def(i)["id"] == "sniper":
					db.selected_index = i
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			_player.position = Vector3(0, 1, 0)
			root.add_child(_player)
			_next("blind")
		"blind":
			if _ticks < 30:
				return false
			var cam: Camera3D = _player.get_node("Camera3D")
			_check(cam.cull_mask == 2, "the Sniper renders only the echo layer")
			_echo = _player.get_node_or_null("EchoVision")
			_check(_echo != null, "the Sniper has echo-sight")
			if _echo == null:
				return _finish()

			# --- palette: WHAT it is decides the hue, HOW OLD
			# decides the shade (STO-CHARACTER-051) ---
			var world_fresh: Color = _echo.call("mark_colour", 0, 0.0)
			var world_old: Color = _echo.call("mark_colour", 0, 0.95)
			_check(world_fresh.b > world_fresh.r and world_fresh.b > world_fresh.g,
					"the room is BLUE (%.2f, %.2f, %.2f)"
					% [world_fresh.r, world_fresh.g, world_fresh.b])
			_check(world_old.b < world_fresh.b and world_old.b < 0.15,
					"and darkens toward black with age (%.2f -> %.2f)"
					% [world_fresh.b, world_old.b])

			var enemy_fresh: Color = _echo.call("mark_colour", 1, 0.0)
			_check(enemy_fresh.r > enemy_fresh.g and enemy_fresh.r > enemy_fresh.b,
					"enemies are RED (%.2f, %.2f, %.2f)"
					% [enemy_fresh.r, enemy_fresh.g, enemy_fresh.b])
			_check(float(_echo.call("mark_colour", 1, 0.95).r) < enemy_fresh.r,
					"enemy marks darken with age too")

			var friend_fresh: Color = _echo.call("mark_colour", 2, 0.0)
			_check(friend_fresh.g > friend_fresh.r and friend_fresh.g > friend_fresh.b,
					"other players are GREEN (%.2f, %.2f, %.2f)"
					% [friend_fresh.r, friend_fresh.g, friend_fresh.b])

			# The three must be tellable apart at a glance.
			_check(world_fresh.b > 0.5 and enemy_fresh.r > 0.5
					and friend_fresh.g > 0.5,
					"all three hues are vivid enough to distinguish")
			_next("scan")
		"scan":
			if _ticks < 5:
				return false
			_player.set_physics_process(false)     # stop our own footsteps
			_echo.set("_marks", [])
			_echo.call("_reindex")
			(_player.get_node("Camera3D") as Camera3D).rotation = Vector3.ZERO
			_player.call("lidar_scan")
			_next("scanned")
		"scanned":
			if _ticks < 60:
				return false
			var lidar := int(_echo.call("lidar_mark_count"))
			_check(lidar > 150,
					"a sweep draws the room in detail (%d marks)" % lidar)

			# Directional, and gaussian: denser straight ahead than at
			# the edge of the cone.
			var ahead := 0
			var behind := 0
			var central := 0
			for m in _echo.call("all_marks"):
				var p: Vector3 = m["pos"]
				if p.z < -5.0:
					ahead += 1
					if absf(p.x) < 4.0:
						central += 1
				elif p.z > 5.0:
					behind += 1
			_check(behind == 0, "the sweep sees nothing behind us (%d)" % behind)
			_check(ahead > 100, "it hits the wall ahead (%d)" % ahead)
			_check(float(central) / float(maxi(ahead, 1)) > 0.45,
					"rays cluster where you look, gaussian not flat (%d of %d central)"
					% [central, ahead])
			_next("rescan")
		"rescan":
			if _ticks < 5:
				return false
			# A second sweep of the same place must REFRESH, not stack:
			# fresh hits replace stale marks near them.
			var before := int(_echo.call("lidar_mark_count"))
			_player.set("_scan_cd", 0.0)
			_player.call("lidar_scan")
			_scan_before = before
			_next("rescanned")
		"rescanned":
			if _ticks < 60:
				return false
			var after := int(_echo.call("lidar_mark_count"))
			_check(after < _scan_before * 2,
					"rescanning refreshes rather than piling up (%d -> %d, not %d)"
					% [_scan_before, after, _scan_before * 2])
			_next("sound")
		"sound":
			if _ticks < 5:
				return false
			var lidar_before := int(_echo.call("lidar_mark_count"))
			# An ACTION anywhere is heard — this is how another player's
			# punches and shots reach a blind Sniper (STO-CHARACTER-050).
			var sounds := root.get_node("/root/Sounds")
			_check(sounds != null, "there is a sound bus")
			sounds.call("make", Vector3(0, 1, -8), 2.0)
			_sound_lidar_before = lidar_before
			_next("heard")
		"heard":
			if _ticks < 40:
				return false
			_check(int(_echo.call("sound_mark_count")) > 0,
					"an action elsewhere is heard (%d sound marks)"
					% int(_echo.call("sound_mark_count")))
			_check(int(_echo.call("lidar_mark_count")) == _sound_lidar_before,
					"hearing something does not disturb the lidar map")
			# Creatures must now be HIT by the rays, not just the wall
			# behind them (STO-CHARACTER-051 reverses the earlier
			# "only the room" rule).
			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "Contact"
			_enemy.position = Vector3(0, 1, -6.0)
			root.add_child(_enemy)
			_next("contact")
		"contact":
			if _ticks < 12:
				return false      # let it enter the physics space
			if _ticks == 12:
				# Hold it still: marks record where it WAS, and a
				# chasing enemy would walk away from its own dots.
				_enemy.set_physics_process(false)
				_echo.set("_marks", [])
				_echo.call("_reindex")
				_player.set("_scan_cd", 0.0)
				_player.call("lidar_scan")
				return false
			if _ticks < 60:
				return false
			_check(int(_echo.call("target_mark_count", 1)) > 0,
					"the enemy itself is marked red (%d hits)"
					% int(_echo.call("target_mark_count", 1)))
			_check(int(_echo.call("target_mark_count", 0)) > 0,
					"the room is still marked blue alongside it (%d)"
					% int(_echo.call("target_mark_count", 0)))
			# Every red mark must actually be ON the creature.
			var stray := 0
			for m in _echo.call("all_marks"):
				if int(m.get("target", 0)) != 1:
					continue
				var d: float = (m["pos"] as Vector3).distance_to(
						_enemy.global_position + Vector3(0, 0.9, 0))
				if d > 1.8:
					stray += 1
			_check(stray == 0, "every red mark is on the enemy (%d stray)" % stray)
			return _finish()
	return false


var _scan_before := 0
var _sound_lidar_before := 0


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
