extends SceneTree
## Smoke test for STO-ENEMIES-011 — enemies fight back.
##   godot --headless -s res://tests/smoke_enemy_attack.gd
##
## Before this, enemy.gd said "Enemies only chase — they do not deal
## damage", so nothing in delve could hurt you.
##
## Guarding and dodge-rolling WERE proven here (3.0 damage vs 12.0,
## and none at all mid-roll) until STO-CHARACTER-056 made C a dead
## key. There is no defence but footwork now, which is what the last
## phase checks.

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _enemy: CharacterBody3D
var _player: CharacterBody3D
var _start_hp := 0.0
var _saw_windup := false
var _swings_before := 0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			# Deliberately does NOT host. Nothing here needs a network,
			# and hosting makes the test unrunnable while the operator
			# has the game open on port 7777.
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_next("grab")
		"grab":
			if _ticks < 3:
				return false
			var players: Node3D = _main.get_node("Players")
			if players.get_child_count() == 0:
				_check(false, "a player spawned")
				return _finish()
			_player = players.get_child(0)
			var enemies: Node3D = _main.get_node("Enemies")
			if enemies.get_child_count() == 0:
				_check(false, "there are enemies")
				return _finish()
			_enemy = enemies.get_child(0)

			# Put them nose to nose on open ground, well clear of the
			# maze and the playground so nothing is between them.
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_enemy.global_position = Vector3(0.0, 1.0, 41.4)
			_start_hp = float(_player.call("health"))
			_check(_start_hp > 0.0, "player starts with health (%.0f)" % _start_hp)
			_check(int(_enemy.call("swings")) == 0, "no blows landed yet")
			_next("fight")
		"fight":
			# Watch for the telegraph: it must rear back BEFORE it hits.
			if bool(_enemy.call("is_winding_up")):
				if int(_enemy.call("swings")) == 0:
					_saw_windup = true
			if _ticks > 240:      # 4 s is plenty for one swing
				_check(_saw_windup,
						"it rears back before striking, so you can see it coming")
				_check(int(_enemy.call("swings")) > 0,
						"the enemy actually hit the player (%d blows)"
						% int(_enemy.call("swings")))
				var hp := float(_player.call("health"))
				_check(hp < _start_hp,
						"the player lost health (%.0f -> %.0f)" % [_start_hp, hp])
				_next("wall")
		"wall":
			if _ticks < 2:
				# THE CHEAP-FEELING BUG: an enemy on the far side of a
				# maze wall must not be able to clobber you through it.
				# The playground wall sits at the origin, so stand on
				# opposite sides of it.
				var wall := _find_wall()
				if wall == null:
					_check(false, "found a wall to hide behind")
					_next("nodefence")
					return false
				var wp: Vector3 = wall.global_position
				_player.global_position = wp + Vector3(0.0, 1.0, -1.2)
				_enemy.global_position = wp + Vector3(0.0, 1.0, 1.2)
				# Count blows, NOT health: players regenerate, so health
				# can rise during the wait and hide a hit that landed.
				_swings_before = int(_enemy.call("swings"))
				return false
			if _ticks > 240:
				var through := int(_enemy.call("swings")) - _swings_before
				_check(through == 0,
						"a wall blocks the attack (%d blows got through)" % through)
				_next("nodefence")
		"nodefence":
			# There is NO defence any more (STO-CHARACTER-056).
			#
			# This phase used to prove that guarding softened a blow to
			# a quarter and a dodge roll took none at all. Both were
			# true, and both were on C — which the operator chose to
			# make a dead key, knowing the cost. Footwork during the
			# 0.55 s wind-up is the only answer now.
			#
			# The block/parry/dodge CODE still exists, unhooked; that
			# the keys do nothing is covered by smoke_dead_keys.gd.
			if _ticks < 2:
				_player.global_position = Vector3(0.0, 1.0, 40.0)
				_player.call("set_health", 100.0)
				Input.action_press("ability_guard")   # dead key
				return false
			if _ticks < 12:
				return false
			_player.call("set_health", 100.0)
			var hp_before := float(_player.call("health"))
			_player.call("hurt_by_enemy", 12.0)
			var lost := hp_before - float(_player.call("health"))
			Input.action_release("ability_guard")
			_check(lost > 11.0,
					"a blow costs full damage even holding C (%.1f)" % lost)
			return _finish()
	return false


func _find_wall() -> Node3D:
	var pg := _main.get_node_or_null("Playground")
	if pg == null:
		return null
	for c in pg.get_children():
		if String(c.name).to_lower().contains("wall"):
			return c as Node3D
	return null


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
