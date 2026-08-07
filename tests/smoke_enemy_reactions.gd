extends SceneTree
## Headless smoke test for STO-ENEMIES-004/005/006 (hit reactions with
## a REAL physics ragdoll and momentum from the procedural build).
##   godot --headless -s res://tests/smoke_enemy_reactions.gd
## No hosting needed — main.tscn spawns enemies in _ready. Verifies:
##   - mass varies across procedurally-generated builds
##   - dv x mass recovers the impulse (true momentum transfer)
##   - weak knockback staggers, strong knockback spawns a ragdoll of
##     real RigidBody3D parts; the body swaps out; parts really tumble
##     (angular velocity) and carry momentum
##   - the enemy travels while ragdolled, then stands back up (body
##     visible, upright, gait re-enabled, ragdoll freed)
##   - trip() ragdolls via the shins and inherits sprint momentum
## Exits 0 on PASS, 1 on FAIL. Budgeted in physics ticks (60/s).

const MAX_TICKS := 2400

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _phase_ticks := 0
var _main: Node
var _enemy: CharacterBody3D
var _down_pos_start := Vector3.ZERO
var _max_ang := 0.0
var _stumble_foot_y := 0.0
var _stumble_hip_y := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	_phase_ticks += 1
	if _ticks > MAX_TICKS:
		_fail("timeout in phase '%s'" % _phase)
		return _finish()

	match _phase:
		"setup":
			_main = load("res://scenes/main.tscn").instantiate()
			root.add_child(_main)
			_enemy = _main.get_node("Enemies/Enemy0") as CharacterBody3D
			_next("settle")
		"settle":
			if _phase_ticks >= 40:  # let everyone land
				_next("momentum")
		"momentum":
			# Procedural generation: each build has its own mass.
			var e1 := _main.get_node("Enemies/Enemy1") as CharacterBody3D
			var e2 := _main.get_node("Enemies/Enemy2") as CharacterBody3D
			var masses := [_enemy.mass(), e1.mass(), e2.mass()]
			_check(masses.max() - masses.min() > 0.01,
					"mass varies across builds (%.2f / %.2f / %.2f)" % masses)
			# Momentum transfer: dv = J/m, so dv*m recovers the impulse.
			var j := Vector3(1.5, 0.0, 0.0)
			var v0: float = _enemy.velocity.x
			var v1: float = e1.velocity.x
			_enemy.apply_knockback(j)
			e1.apply_knockback(j)
			var r0: float = (_enemy.velocity.x - v0) * _enemy.mass()
			var r1: float = (e1.velocity.x - v1) * e1.mass()
			_check(absf(r0 - 1.5) < 0.05 and absf(r1 - 1.5) < 0.05,
					"dv x mass recovers the impulse (%.2f, %.2f)" % [r0, r1])
			# WEAK tier: a shove only — no stumble, no ragdoll.
			_check(not _enemy.is_downed() and not _enemy.is_stumbling(),
					"weak hit only shoves — no stumble, no ragdoll")
			_next("stumble_hit")
		"stumble_hit":
			if _phase_ticks < 40:
				return false  # let the shove settle
			# MEDIUM tier: guaranteed stumble band for this build.
			_enemy.apply_knockback(Vector3(3.0, 0.0, 0.0))
			_check(_enemy.is_stumbling() and not _enemy.is_downed(),
					"medium hit stumbles but stays up")
			# The stumble must be a LEG buckling (STO-ENEMIES-008), not
			# just a body lean.
			var body: Node3D = _enemy.get_node("Body")
			_check(bool(body.call("is_buckling")),
					"a leg buckles during the stumble")
			_stumble_foot_y = body.call("foot_world", _enemy.get("_stumble_leg")).y
			_stumble_hip_y = body.call("hip_world", _enemy.get("_stumble_leg")).y
			_next("stumble_collapse")
		"stumble_collapse":
			if _phase_ticks < 12:
				return false
			var body2: Node3D = _enemy.get_node("Body")
			var leg: int = _enemy.get("_stumble_leg")
			var hip_now: float = body2.call("hip_world", leg).y
			var foot_now: float = body2.call("foot_world", leg).y
			# The buckling leg folds: hip-to-foot distance shrinks.
			var before := _stumble_hip_y - _stumble_foot_y
			var now := hip_now - foot_now
			_check(now < before - 0.05,
					"the buckling leg folds under them (%.2f m -> %.2f m)"
					% [before, now])
			_next("stumble_recover")
		"stumble_recover":
			if _enemy.is_stumbling():
				if _phase_ticks > 120:
					_fail("stumble never ended")
					return _finish()
				return false
			var b: Node3D = _enemy.get_node("Body")
			var lean: float = b.transform.basis.get_rotation_quaternion() \
					.angle_to(Quaternion.IDENTITY)
			_check(lean < 0.1,
					"body upright again after the stumble (%.2f rad)" % lean)
			_check(not bool(b.call("is_buckling")),
					"the leg recovers after the stumble")
			_next("strong_hit")
		"strong_hit":
			if _phase_ticks < 40:
				return false  # let the stumble momentum settle
			_enemy.apply_knockback(Vector3(8.0, 0.0, 6.0))  # |J| = 10
			_check(_enemy.is_downed(), "strong knockback knocks it down")
			var rag: Node3D = _enemy.ragdoll()
			_check(rag != null, "a REAL ragdoll node exists")
			if rag == null:
				return _finish()
			_check(int(rag.call("part_count")) >= 9,
					"ragdoll has RigidBody3D parts (%d)" % int(rag.call("part_count")))
			_check(rag.call("part", "Pelvis") is RigidBody3D,
					"parts are real RigidBody3D physics bodies")
			_check(not _enemy.get_node("Body").visible,
					"procedural body hidden while ragdolled")
			_down_pos_start = _enemy.global_position
			_max_ang = 0.0
			_next("ragdolling")
		"ragdolling":
			var rag: Node3D = _enemy.ragdoll()
			if rag != null:
				var pelvis: RigidBody3D = rag.call("part", "Pelvis")
				if pelvis != null:
					_max_ang = maxf(_max_ang, pelvis.angular_velocity.length())
				return false
			# Ragdoll ended — enemy is getting up / up.
			_check(_max_ang > 1.0,
					"parts really tumbled (max pelvis angular vel %.1f rad/s)"
					% _max_ang)
			var moved := _enemy.global_position - _down_pos_start
			moved.y = 0.0
			_check(moved.length() > 1.0,
					"enemy carried by momentum while down (%.1f m)" % moved.length())
			_next("recovering")
		"recovering":
			if _enemy.is_downed():
				if _phase_ticks > 600:
					_fail("enemy never finished getting up")
					return _finish()
				return false
			var body: Node3D = _enemy.get_node("Body")
			_check(body.visible, "body visible again after getting up")
			var upright: float = body.transform.basis.get_rotation_quaternion() \
					.angle_to(Quaternion.IDENTITY)
			_check(upright < 0.15, "body upright again (%.2f rad)" % upright)
			_check(body.is_processing(), "gait re-enabled after getting up")
			_check(_enemy.ragdoll() == null, "ragdoll freed after recovery")
			_next("trip_sprint")
		"trip_sprint":
			# Own momentum: trip a sprinting enemy — its ragdoll parts
			# inherit the sprint velocity (momentum conservation).
			_enemy.velocity = Vector3(8.0, 0.0, 0.0)
			_enemy.trip(Vector3(3.0, 0.0, 0.0))
			_check(_enemy.is_downed(), "trip() ragdolls (tail hook)")
			var rag: Node3D = _enemy.ragdoll()
			if rag != null:
				var pelvis: RigidBody3D = rag.call("part", "Pelvis")
				_check(pelvis.linear_velocity.x > 6.0,
						"parts inherit sprint momentum (pelvis vx=%.1f)"
						% pelvis.linear_velocity.x)
			return _finish()
	return false


func _next(phase: String) -> void:
	_phase = phase
	_phase_ticks = 0


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


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
