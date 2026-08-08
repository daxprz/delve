extends SceneTree
## Smoke test for STO-ENEMIES-013 / 014 / 015 — what losing a limb DOES.
##   godot --headless -s res://tests/smoke_limb_effects.gd
##
##   head off      -> instant death, even at full health
##   one leg off   -> it can only limp
##   both legs off -> death
##   one arm off   -> its hits are much weaker
##   both arms off -> it cannot hurt you at all, but still chases

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _enemies: Node3D
var _subject: CharacterBody3D
var _whole_damage := 0.0
var _one_arm_damage := 0.0
var _limp_start := Vector3.ZERO


## Drop a fresh enemy in and ragdoll it, so its limbs can be taken.
func _fresh(nm: String, at: Vector3) -> CharacterBody3D:
	var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
	e.name = nm
	_enemies.add_child(e)
	e.global_position = at
	return e


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			_enemies = _main.get_node("Enemies")
			# Clear the scene's own enemies so corpse-reaping can't
			# collect our subjects mid-test.
			for c in _enemies.get_children():
				c.free()
			_subject = _fresh("Head1", Vector3(0.0, 1.0, 40.0))
			_next("head_down")
		"head_down":
			if _ticks < 4:
				return false
			if _ticks == 4:
				_subject.call("apply_knockback", Vector3(0, 2, -9) * 60.0)
				return false
			if _ticks < 10:
				return false
			# THE POINT of 013: full health, and the head still kills.
			_check(float(_subject.call("health")) > 50.0,
					"the enemy is at full health (%.0f)"
					% float(_subject.call("health")))
			_check(bool(_subject.call("tear_off_limb", "head")),
					"its head comes off")
			_check(bool(_subject.call("is_dead")),
					"losing the head kills it instantly, at full health")
			_next("legs")
		"legs":
			if _ticks < 2:
				return false
			if _ticks == 2:
				_subject = _fresh("Legs1", Vector3(4.0, 1.0, 40.0))
				return false
			if _ticks < 6:
				return false
			if _ticks == 6:
				_subject.call("apply_knockback", Vector3(0, 2, -9) * 60.0)
				return false
			if _ticks < 12:
				return false
			_check(bool(_subject.call("tear_off_limb", "leg_l")),
					"one leg comes off")
			_check(not bool(_subject.call("is_dead")),
					"losing ONE leg does not kill it")
			_check(int(_subject.call("legs_left")) == 1,
					"one leg left (%d)" % int(_subject.call("legs_left")))
			_next("limp")
		"limp":
			# It must be slower — measured, not guessed.
			if _ticks < 150:
				return false
			var whole_speed := 3.0        # Enemy.SPEED
			var limp := float(_subject.call("_move_speed"))
			_check(limp > 0.0, "a one-legged enemy can still move (%.2f)" % limp)
			_check(limp < whole_speed * 0.75,
					"...but clearly slower than a whole one (%.2f vs %.2f)"
					% [limp, whole_speed])
			_check(bool(_subject.call("tear_off_limb", "leg_r")),
					"the second leg comes off")
			_check(bool(_subject.call("is_dead")),
					"losing BOTH legs kills it")
			_next("arms")
		"arms":
			if _ticks < 2:
				return false
			if _ticks == 2:
				_subject = _fresh("Arms1", Vector3(8.0, 1.0, 40.0))
				return false
			if _ticks < 6:
				return false
			if _ticks == 6:
				_whole_damage = float(_subject.call("attack_damage"))
				_check(_whole_damage > 0.0,
						"a whole enemy hits for %.1f" % _whole_damage)
				_subject.call("apply_knockback", Vector3(0, 2, -9) * 60.0)
				return false
			if _ticks < 12:
				return false
			_check(bool(_subject.call("tear_off_limb", "arm_l")),
					"one arm comes off")
			_one_arm_damage = float(_subject.call("attack_damage"))
			_check(_one_arm_damage < _whole_damage,
					"one arm gone = clearly less damage (%.1f vs %.1f)"
					% [_one_arm_damage, _whole_damage])
			_check(_one_arm_damage > 0.0,
					"...but it can still hurt you (%.1f)" % _one_arm_damage)
			_check(not bool(_subject.call("is_dead")),
					"losing an arm does not kill it")

			_check(bool(_subject.call("tear_off_limb", "arm_r")),
					"the second arm comes off")
			_check(is_equal_approx(float(_subject.call("attack_damage")), 0.0),
					"both arms gone = ZERO damage (%.1f)"
					% float(_subject.call("attack_damage")))
			_check(not bool(_subject.call("is_dead")),
					"an armless enemy is harmless, NOT dead")
			_check(float(_subject.call("_move_speed")) > 0.0,
					"...and it still chases you (%.2f)"
					% float(_subject.call("_move_speed")))
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
