extends SceneTree
## Smoke test for STO-CHARACTER-033 (pounce cooldown + hit refund).
## Non-hosted so it runs while a game is open.
##   godot --headless -s res://tests/smoke_pounce_cooldown.gd
## Verifies:
##   - pounce starts ready (cooldown 0)
##   - a MISSED pounce sets a ~15 s cooldown
##   - while on cooldown, holding Space does NOT charge or launch
##   - a pounce that connects with an enemy refunds the cooldown to 0
##     (so it can be chained immediately)

const CHARGE := 60

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _enemy: CharacterBody3D
var _cam_after_cd := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(400, 1, 400)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 1  # Runner
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_next("ready_check")
		"ready_check":
			if _ticks < 40:
				return false
			_check(_player.pounce_cooldown() == 0.0, "pounce starts ready")
			Input.action_press("jump")
			_next("charge_miss")
		"charge_miss":
			if _ticks >= CHARGE:
				Input.action_release("jump")
				_next("miss_landed")
		"miss_landed":
			if not _player.is_on_floor() or _ticks < 10:
				if _ticks > 400:
					_fail("never landed after the missed pounce")
					return _finish()
				return false
			var cd: float = _player.pounce_cooldown()
			_check(cd > 13.0 and cd <= 15.0,
					"a MISSED pounce starts the ~15 s cooldown (%.1f s)" % cd)
			# Try to pounce again while on cooldown.
			_cam_after_cd = (_player.get_node("Camera3D") as Camera3D).position.y
			Input.action_press("jump")
			_next("blocked")
		"blocked":
			if _ticks < 30:
				return false
			var cam: float = (_player.get_node("Camera3D") as Camera3D).position.y
			_check(is_equal_approx(cam, _cam_after_cd),
					"no crouch/charge while on cooldown")
			Input.action_release("jump")
			_check(_player.pounce_cooldown() > 10.0,
					"still on cooldown after the blocked attempt (%.1f s)"
					% _player.pounce_cooldown())
			# Now set up a HIT: clear the cooldown, park an enemy right
			# in the pounce path, and pounce into it.
			_player.set("_pounce_cd", 0.0)
			var enemy_script: GDScript = load("res://scripts/enemy.gd")
			_enemy = enemy_script.new()
			_enemy.name = "Target"
			var fwd := -_player.global_transform.basis.z
			fwd.y = 0.0
			_enemy.position = _player.global_position + fwd.normalized() * 6.0
			root.add_child(_enemy)
			Input.action_press("jump")
			_next("charge_hit")
		"charge_hit":
			if _ticks >= CHARGE:
				Input.action_release("jump")
				_next("hit_flight")
		"hit_flight":
			# The pounce arc passes through the enemy: cooldown refunds.
			if _player.pounce_cooldown() == 0.0 and _ticks > 3:
				_check(true, "pouncing INTO an enemy refunds the cooldown")
				_check(bool(_player.get("_pounce_hit")),
						"the hit was registered")
				return _finish()
			if _ticks > 400:
				_check(false, "pounce hit never refunded the cooldown (%.1f s left)"
						% _player.pounce_cooldown())
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


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
