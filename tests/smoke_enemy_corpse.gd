extends SceneTree
## Smoke test for STO-ENEMIES-016 — dead bodies stay.
##   godot --headless -s res://tests/smoke_enemy_corpse.gd
##
## enemy.gd used to free the ragdoll and then free the enemy, so a
## defeated enemy popped out of existence mid-fight. Everything delve
## built for physical fighting — the Grabber's arms, the Runner's tail,
## throwing, dragging — stopped working the instant a thing died.
##
## Found by the operator while playing, not by reading code.

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _enemy: CharacterBody3D
var _enemies: Node3D
var _rag: Node3D
var _pelvis: RigidBody3D
var _rest_pos := Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			_enemies = _main.get_node("Enemies")
			if _enemies.get_child_count() == 0:
				_check(false, "there are enemies")
				return _finish()
			_enemy = _enemies.get_child(0)
			_enemy.global_position = Vector3(0.0, 1.0, 40.0)
			_check(not bool(_enemy.call("is_dead")), "it starts alive")
			_next("kill")
		"kill":
			if _ticks < 3:
				return false
			if _ticks == 3:
				# Kill it outright while it is still on its feet — the
				# hardest case, because there is no ragdoll to keep.
				_enemy.call("take_damage", 1000.0)
				return false
			if _ticks < 8:
				return false
			_check(is_instance_valid(_enemy), "the enemy was NOT deleted")
			if not is_instance_valid(_enemy):
				return _finish()
			_check(bool(_enemy.call("is_dead")), "it knows it is dead")
			_rag = _enemy.get_parent().get_node_or_null(
					String(_enemy.name) + "Ragdoll")
			_check(_rag != null, "it left a body behind")
			if _rag == null:
				return _finish()
			_check(int(_rag.call("part_count")) > 0,
					"the body has real physics parts (%d)"
					% int(_rag.call("part_count")))
			_pelvis = _rag.call("part", "Pelvis")
			_check(_pelvis != null, "the body has a pelvis to shove")
			_next("settle")
		"settle":
			if _ticks < 120:
				return false
			# It must lie there — not get up, not chase.
			_check(bool(_enemy.call("is_dead")), "it stays dead")
			_check(is_instance_valid(_rag), "the body is still there after 2 s")
			if not is_instance_valid(_rag) or _pelvis == null:
				return _finish()
			_check(is_instance_valid(_pelvis), "its parts are still there")
			_rest_pos = _pelvis.global_position
			_next("shove")
		"shove":
			if _ticks == 1:
				# THE POINT: you can still knock the body around.
				_enemy.call("apply_knockback", Vector3(0.0, 4.0, -18.0) * 60.0)
				return false
			if _ticks < 30:
				return false
			_check(_pelvis.global_position.distance_to(_rest_pos) > 0.4,
					"the body can still be shoved around (%.2f m)"
					% _pelvis.global_position.distance_to(_rest_pos))
			_next("nokill")
		"nokill":
			# A corpse cannot be killed twice, and must not respawn.
			var before := float(_enemy.call("health"))
			_enemy.call("take_damage", 500.0)
			_check(is_equal_approx(float(_enemy.call("health")), before),
					"a corpse takes no more damage")
			_check(is_instance_valid(_enemy), "and is not deleted by it")
			_next("cap")
		"cap":
			# Bodies must not pile up forever — each is 11 rigid parts.
			if _ticks == 1:
				for c in _enemies.get_children():
					if c.has_method("take_damage"):
						c.call("take_damage", 1000.0)
				# Add plenty more and kill them too.
				for i in 12:
					var e: CharacterBody3D = \
							load("res://scenes/enemy.tscn").instantiate()
					e.name = "Extra%d" % i
					_enemies.add_child(e)
				return false
			if _ticks < 5:
				return false
			if _ticks == 5:
				for c in _enemies.get_children():
					if c.has_method("take_damage"):
						c.call("take_damage", 1000.0)
				return false
			if _ticks < 12:
				return false
			var corpses := 0
			for c in _enemies.get_children():
				if c.has_method("is_dead") and bool(c.call("is_dead")):
					corpses += 1
			_check(corpses <= 8,
					"bodies do not pile up forever (%d kept, cap 8)" % corpses)
			_check(corpses > 0, "...but some are kept (%d)" % corpses)
			return _finish()
	return false


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
