extends SceneTree
## Smoke test for STO-ENEMIES-017 (enemy kinds) and STO-ENEMIES-018
## (the four-legged crawler).
##   godot --headless -s res://tests/smoke_crawler.gd
##
## delve had exactly one creature: 60 health, walks at you, swings for
## 12. Its body varied with a seed but it always BEHAVED the same and
## always looked like the same humanoid.
##
## The gait is the part worth checking. A humanoid plants two feet; a
## four-legged thing has to step so it is never left unsupported, which
## means diagonal pairs moving together.

const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _crawler: CharacterBody3D
var _walker: CharacterBody3D
var _body: Node3D
var _feet_a: Array = []


func _spawn(kind: int, nm: String, at: Vector3) -> CharacterBody3D:
	var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
	e.name = nm
	e.set("kind", kind)
	_main.get_node("Enemies").add_child(e)
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
			# --- the registry (STO-ENEMIES-017) ---------------------
			_check(EnemyKinds.count() >= 2,
					"there is more than one kind of enemy (%d)"
					% EnemyKinds.count())
			_check(EnemyKinds.index_of("walker") >= 0, "the Walker is a kind")
			var ci := EnemyKinds.index_of("crawler")
			_check(ci >= 0, "the Crawler is a kind")
			if ci < 0:
				return _finish()

			# A player to chase. Without one the enemy stands still, and
			# the enemy overwrites set_speed() with its REAL velocity
			# every tick — so a test that just calls set_speed(4) is
			# measuring a creature that is not going anywhere.
			var pl: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			pl.name = "1"
			_main.get_node("Players").add_child(pl)
			pl.global_position = Vector3(0.0, 1.0, 20.0)
			_walker = _spawn(EnemyKinds.index_of("walker"), "W1",
					Vector3(0.0, 1.0, 40.0))
			_crawler = _spawn(ci, "C1", Vector3(4.0, 1.0, 40.0))
			_next("built")
		"built":
			if _ticks < 5:
				return false
			_check(String(_crawler.call("kind_id")) == "crawler",
					"the crawler knows what it is (%s)"
					% String(_crawler.call("kind_id")))
			_check(String(_walker.call("kind_id")) == "walker",
					"the walker is unchanged (%s)"
					% String(_walker.call("kind_id")))
			# Different kinds really are different, not a reskin.
			_check(not is_equal_approx(float(_crawler.call("max_health")),
							float(_walker.call("max_health"))),
					"they have different health (%.0f vs %.0f)"
					% [float(_crawler.call("max_health")),
					float(_walker.call("max_health"))])

			_body = _crawler.get_node_or_null("Body") as Node3D
			_check(_body != null, "the crawler has a body")
			if _body == null:
				return _finish()

			# --- FOUR LEGS AND A BLOCK -----------------------------
			_check(int(_body.call("leg_count")) == 4,
					"it has exactly 4 legs (%d)" % int(_body.call("leg_count")))
			var size: Vector3 = _body.call("body_size")
			_check(size.x > 0.0 and size.y > 0.0 and size.z > 0.0,
					"its body is a block (%.2f x %.2f x %.2f)"
					% [size.x, size.y, size.z])
			_check(size.y < size.z,
					"a low block, not a standing figure (%.2f tall vs %.2f long)"
					% [size.y, size.z])

			# The humanoid body has no legs to count — proving these
			# really are two different shapes, not one with a flag.
			var wbody := _walker.get_node_or_null("Body") as Node3D
			_check(wbody != null and not wbody.has_method("leg_count"),
					"the walker is a different shape entirely")
			# --- SPIDER SHAPE (STO-ENEMIES-019) --------------------
			_check(_body.get_node_or_null("Head") == null,
					"one block only — no separate head")
			var feet: Array = _body.call("foot_positions")
			var knees: Array = _body.call("knee_positions")
			var bh: float = _body.call("body_height")
			var half_w: float = size.x * 0.5
			var outside := 0
			for f in feet:
				if absf((f as Vector3).x) > half_w:
					outside += 1
			_check(outside == 4,
					"all 4 feet land OUTSIDE the body's width (%d of 4, half-width %.2f)"
					% [outside, half_w])
			var above := 0
			for k in knees:
				if (k as Vector3).y > bh:
					above += 1
			_check(above == 4,
					"all 4 knees rise ABOVE the body (%d of 4, body at %.2f)"
					% [above, bh])
			_next("gait")
		"gait":
			# --- IT STEPS -------------------------------------------
			if _ticks < 20:
				return false     # let it get moving toward the player
			if _ticks == 20:
				_feet_a = _body.call("foot_positions")
				_check(_feet_a.size() == 4, "there are 4 feet to watch")
				return false
			if _ticks < 40:
				return false
			var feet_b: Array = _body.call("foot_positions")
			var moved := 0
			for i in mini(_feet_a.size(), feet_b.size()):
				if (_feet_a[i] as Vector3).distance_to(feet_b[i] as Vector3) > 0.005:
					moved += 1
			_check(moved > 0,
					"its legs actually step rather than sliding (%d of 4 moved)"
					% moved)

			# --- DIAGONAL PAIRS -------------------------------------
			# FL+BR move together, FR+BL move together — so one
			# diagonal is always down and it is never unsupported.
			var d_fl := (_feet_a[0] as Vector3).distance_to(feet_b[0] as Vector3)
			var d_fr := (_feet_a[1] as Vector3).distance_to(feet_b[1] as Vector3)
			var d_bl := (_feet_a[2] as Vector3).distance_to(feet_b[2] as Vector3)
			var d_br := (_feet_a[3] as Vector3).distance_to(feet_b[3] as Vector3)
			_check(absf(d_fl - d_br) < absf(d_fl - d_fr) + 0.02,
					"front-left moves with back-right, not with front-right")
			_check(absf(d_fr - d_bl) < absf(d_fr - d_br) + 0.02,
					"front-right moves with back-left")
			_next("still")
		"still":
			# Standing still, the legs stop. A creature jogging on the
			# spot looks broken.
			if _ticks == 1:
				# Take the player away so it genuinely stops. Calling
				# set_speed(0) alone does nothing — the enemy overwrites
				# it with its REAL velocity every tick, which is the
				# point of driving the gait from actual movement.
				for c in _main.get_node("Players").get_children():
					c.queue_free()
				return false
			if _ticks == 40:
				_feet_a = _body.call("foot_positions")
				return false
			if _ticks < 60:
				return false
			var feet_c: Array = _body.call("foot_positions")
			var still := true
			for i in mini(_feet_a.size(), feet_c.size()):
				if (_feet_a[i] as Vector3).distance_to(feet_c[i] as Vector3) > 0.005:
					still = false
			_check(still, "a standing crawler does not jog on the spot")
			_next("hurt")
		"hurt":
			# It is still an enemy: it ragdolls and leaves a body.
			if _ticks == 1:
				_crawler.call("apply_knockback", Vector3(0.0, 2.0, -12.0) * 60.0)
				return false
			if _ticks < 10:
				return false
			var rag := _crawler.get_parent().get_node_or_null("C1Ragdoll")
			_check(rag != null, "a hard hit ragdolls the crawler too")
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
