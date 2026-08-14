extends SceneTree
## Smoke test for STO-ENEMIES-012 — limbs can be torn off.
##   godot --headless -s res://tests/smoke_enemy_limbs.gd
##
## The foundation of EPI-ENEMIES-ENEMY-LIMBS: head-kills, leg limps
## and weakened arms are all just consequences of a limb being gone,
## so none of them can exist until one can actually come off.

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _enemy: CharacterBody3D
var _rag: Node3D
var _arm: RigidBody3D
var _arm_pos := Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var enemies: Node3D = _main.get_node("Enemies")
			if enemies.get_child_count() == 0:
				_check(false, "there are enemies")
				return _finish()
			_enemy = enemies.get_child(0)
			_enemy.global_position = Vector3(0.0, 1.0, 40.0)

			_check(int(_enemy.call("legs_left")) == 2, "starts with two legs")
			_check(int(_enemy.call("arms_left")) == 2, "starts with two arms")
			_check(bool(_enemy.call("has_limb", "head")), "starts with a head")

			# A limb cannot come off a standing enemy.
			_check(not bool(_enemy.call("tear_off_limb", "arm_l")),
					"a standing enemy keeps its arms")
			_next("weak")
		"weak":
			if _ticks < 3:
				return false
			if _ticks == 3:
				# A hit hard enough to knock it down but NOT to pull it
				# apart. KNOCKDOWN_DV is 7.5, DISMEMBER_DV is 14.
				_enemy.call("apply_knockback", Vector3(0.0, 2.0, -9.0) * 60.0,
						_enemy.global_position + Vector3.UP)
				return false
			if _ticks < 8:
				return false
			_rag = _enemy.get_parent().get_node_or_null(
					String(_enemy.name) + "Ragdoll")
			_check(_rag != null, "a hard hit ragdolled it")
			if _rag == null:
				return _finish()
			_check(int(_rag.call("detached_count")) == 0,
					"a knockdown does NOT tear limbs off (%d came off)"
					% int(_rag.call("detached_count")))
			_check(_enemy.call("lost_limbs").is_empty(),
					"...and it has lost nothing")
			_next("tear")
		"tear":
			if _ticks < 2:
				return false
			if _ticks == 2:
				# Now a genuinely brutal blow, aimed at the left arm.
				var arm: RigidBody3D = _rag.call("part", "UpperArmL")
				_check(arm != null, "the ragdoll has an upper left arm")
				if arm == null:
					return _finish()
				_enemy.call("apply_knockback",
						Vector3(0.0, 1.0, -30.0) * 60.0, arm.global_position)
				return false
			if _ticks < 6:
				return false
			_check(bool(_rag.call("is_detached", "UpperArmL")),
					"a brutal blow tears the arm off")
			_check(not bool(_enemy.call("has_limb", "arm_l")),
					"the enemy knows the arm is gone")
			_check(int(_enemy.call("arms_left")) == 1,
					"one arm left (%d)" % int(_enemy.call("arms_left")))
			_check(int(_enemy.call("legs_left")) == 2,
					"its legs are untouched")
			# The forearm must come away WITH the upper arm, not stay
			# floating where the arm used to be.
			_check(not bool(_rag.call("is_detached", "ForearmL")),
					"the forearm is still joined to what came off")
			_arm = _rag.call("part", "UpperArmL")
			_arm_pos = _arm.global_position
			_next("falls")
		"falls":
			# A loose limb is a real object: it must fall and settle.
			if _ticks < 180:   # 3 s: time to actually land
				return false
			_check(is_instance_valid(_arm), "the loose arm still exists")
			if not is_instance_valid(_arm):
				return _finish()
			# Assert it ends up ON THE FLOOR, not merely lower than it
			# was at the instant of detachment. The ragdoll is still
			# flying when the arm comes off, so "lower than the detach
			# point" depends on where in its arc it happened to be —
			# that made this flake when the body was on the way up.
			_check(_arm.global_position.y < 1.5,
					"the loose arm falls to the floor (y %.2f -> %.2f)"
					% [_arm_pos.y, _arm.global_position.y])
			# The rest of the body must not have exploded where the arm
			# was — delve has been bitten by joint instability before.
			var pelvis: RigidBody3D = _rag.call("part", "Pelvis")
			_check(pelvis != null and pelvis.linear_velocity.length() < 25.0,
					"the body stays stable where the limb came off (%.1f m/s)"
					% (pelvis.linear_velocity.length() if pelvis != null else -1.0))
			_check(pelvis != null and pelvis.global_position.length() < 200.0,
					"...and has not been flung across the map")
			# Taking the same limb twice does nothing.
			_check(not bool(_enemy.call("tear_off_limb", "arm_l")),
					"an arm already gone cannot come off twice")
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
