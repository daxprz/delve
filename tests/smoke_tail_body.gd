extends SceneTree
## Smoke test for STO-CHARACTER-034/035: the Runner's tail must rest
## ON the player and never pass through ANY body part — torso, head,
## arms or legs. Non-hosted.
##   godot --headless -s res://tests/smoke_tail_body.gd
## Verifies:
##   - the body exposes a full capsule set (torso + head + arms + legs)
##   - no tail point is inside ANY bone capsule, at rest or walking
##     (walking swings the arms and legs, so the capsules move)
##   - the tail still hangs (it wasn't just shoved far away)
##   - the Verlet chain stays stable

const SETTLE := 120
const WALK := 60
const TORSO_RADIUS := 0.34
const TORSO_LOW := 0.30
const TORSO_HIGH := 1.45
const SKIN := 0.02   # tolerance

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _tail: Node
var _body: Node


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(80, 1, 80)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 1  # Runner (has the tail)
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_tail = _player.get_node_or_null("Tail")
			_body = _player.get_node_or_null("Body")
			if _tail == null or _body == null:
				_fail("Runner has no Tail/Body")
				return _finish()
			_check(_body.has_method("body_capsules"),
					"body exposes full capsule set")
			# Runner has human arms: legs(4) + torso + head + arms(4).
			var caps: Array = _body.call("body_capsules")
			_check(caps.size() >= 10,
					"capsule set covers torso, head, arms and legs (%d)"
					% caps.size())
			_next("settle")
		"settle":
			if _ticks < SETTLE:
				return false
			_check_clear("at rest")
			# Hanging check: the tail should still reach down/behind,
			# not be flung off somewhere.
			var tip: Vector3 = _tail.call("tip_point")
			var base: Vector3 = _tail.call("base_point")
			_check(tip.distance_to(base) < 6.0,
					"tail still hangs near the player (%.1f m)"
					% tip.distance_to(base))
			Input.action_press("move_forward")
			_next("walk")
		"walk":
			if _ticks < WALK:
				return false
			Input.action_release("move_forward")
			_check_clear("while walking")
			_check(bool(_tail.call("is_finite_chain")),
					"tail chain stays finite (no solver blow-up)")
			# STRESS: the checks above pass with room to spare, so prove
			# the constraint actually fires — jam tail points INTO the
			# head, torso and an arm and require them to be ejected.
			_jam_into_body()
			_next("jammed")
		"jammed":
			if _ticks < 3:
				return false
			_check_clear("after being jammed into the body")
			_check(bool(_tail.call("is_finite_chain")),
					"chain still finite after the jam")
			return _finish()
	return false


## No tail point may be inside ANY body bone capsule.
func _check_clear(when: String) -> void:
	var caps: Array = _body.call("body_capsules")
	var worst := 999.0
	var worst_idx := -1
	var n: int = _tail.call("tail_length") + 1
	for i in range(2, n):
		var p: Vector3 = _tail.call("point_at", i)
		for ci in caps.size():
			var cap: Array = caps[ci]
			var clearance := _dist_to_capsule(p, cap[0], cap[1]) - float(cap[2])
			if clearance < worst:
				worst = clearance
				worst_idx = ci
	_check(worst > -SKIN,
			"no tail point inside any body part %s (worst clearance %.3f m on capsule %d)"
			% [when, worst, worst_idx])


## Teleport several tail points to the exact centre of body capsules
## (head, torso, an arm) — the solver must eject them.
func _jam_into_body() -> void:
	var caps: Array = _body.call("body_capsules")
	var n: int = _tail.call("tail_length") + 1
	var i := 3
	for ci in caps.size():
		if i >= n:
			break
		var cap: Array = caps[ci]
		var mid: Vector3 = (cap[0] + cap[1]) * 0.5
		_tail.call("set_point_for_test", i, mid)
		i += 1
	print("  (jammed %d tail points into body capsule centres)" % (i - 3))


func _dist_to_capsule(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 1e-6:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


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
