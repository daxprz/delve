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
var _climb_from := 0.0


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
			# NB: no longer "knees above the body". STO-ENEMIES-022 made
			# the upper two joints SMALL and the last one long, so the
			# knee now sits near the body rather than towering over it —
			# the shape changed by request. What still has to hold is
			# the down-up-down profile, checked above, and that the
			# knees are OUT to the side rather than tucked under.
			var out_wide := 0
			for k in knees:
				if absf((k as Vector3).x) > half_w:
					out_wide += 1
			_check(out_wide == 4,
					"all 4 knees sit OUT beyond the body (%d of 4)" % out_wide)
			# --- GIANT (STO-ENEMIES-021) ---------------------------
			# Three segments: DOWN off the body, UP to the knee, DOWN
			# to the floor. Two could only manage out-up-down.
			var seg_names := ["Upper", "Lower", "Foot"]
			var node2: Node3D = _body.get_node_or_null("LegFL")
			var ys: Array = []
			for nm3 in seg_names:
				node2 = node2.get_node_or_null(nm3) as Node3D if node2 != null else null
				if node2 != null:
					ys.append(_body.to_local(node2.global_position).y)
			_check(ys.size() == 3,
					"each leg has 3 segments (%d)" % ys.size())
			# The LAST segment must be far the longest (STO-ENEMIES-022).
			var segs: Array = _body.call("segment_lengths")
			_check(segs.size() == 3, "3 segment lengths (%d)" % segs.size())
			if segs.size() == 3:
				_check(float(segs[2]) > float(segs[0]) + float(segs[1]),
						"the last segment is longer than the other two together (%.2f vs %.2f + %.2f)"
						% [float(segs[2]), float(segs[0]), float(segs[1])])
			if ys.size() == 3:
				var bh0: float = _body.call("body_height")
				_check(float(ys[1]) < bh0,
						"the first segment goes DOWN off the body (%.2f vs body %.2f)"
						% [float(ys[1]), bh0])
				_check(float(ys[2]) > float(ys[1]),
						"the second goes UP to the knee (%.2f -> %.2f)"
						% [float(ys[1]), float(ys[2])])
			# It LUMBERS: slower than the plain Walker.
			_check(float(_crawler.call("_move_speed"))
							< float(_walker.call("_move_speed")),
					"it moves slower than the Walker (%.1f vs %.1f)"
					% [float(_crawler.call("_move_speed")),
					float(_walker.call("_move_speed"))])
			# And it is far harder to topple.
			_check(float(_crawler.get("_stability"))
							> float(_walker.get("_stability")) * 1.5,
					"it is much sturdier (%.2f vs %.2f)"
					% [float(_crawler.get("_stability")),
					float(_walker.get("_stability"))])

			# --- IT TOWERS (STO-ENEMIES-020) -----------------------
			var bh2: float = _body.call("body_height")
			# Measured against the PLAYER's real eye height, not a
			# guessed number.
			var pl2 := _main.get_node_or_null("Players/1") as Node3D
			var eye_h := 1.6
			if pl2 != null and pl2.get_node_or_null("Camera3D") != null:
				eye_h = (pl2.get_node("Camera3D") as Node3D).position.y
			_check(bh2 > eye_h,
					"its body rides above the player's head (%.2f vs eye %.2f)"
					% [bh2, eye_h])
			# ...and the feet still reach the floor. Raising the body
			# without deriving it from the legs leaves them dangling.
			var lowest := 999.0
			for f2 in _body.call("foot_positions"):
				lowest = minf(lowest, (f2 as Vector3).y)
			_check(absf(lowest) < 0.25,
					"the feet still reach the ground (lowest foot y %.2f)"
					% lowest)
			# The hitbox grew with it.
			var col := _crawler.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col == null:
				for ch in _crawler.get_children():
					if ch is CollisionShape3D:
						col = ch
			var cap := col.shape as CapsuleShape3D if col != null else null
			_check(cap != null and cap.height > 2.0,
					"its hitbox grew to match (%.2f tall)"
					% (cap.height if cap != null else -1.0))
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
			# --- EVERY STEP IS DIFFERENT (STO-ENEMIES-026) ---------
			# Sample how high each step lifts; a looping gait gives the
			# same answer every time.
			var lifts: Array = []
			for step in 6:
				var jj: Vector3 = _body.call("_step_jitter", 0, step)
				lifts.append(snappedf(jj.x, 0.001))
			var uniq := {}
			for l in lifts:
				uniq[l] = true
			_check(uniq.size() >= 5,
					"consecutive steps differ (%d distinct of 6)" % uniq.size())
			# ...but the SAME step is identical every time it is asked
			# for, or each machine would show a different spider.
			var again: Vector3 = _body.call("_step_jitter", 0, 3)
			var again2: Vector3 = _body.call("_step_jitter", 0, 3)
			_check(again.is_equal_approx(again2),
					"the same step is repeatable, so every peer matches")
			# Diagonal partners share a step, or the pairing breaks.
			_check(not _body.call("_step_jitter", 0, 3).is_equal_approx(
							_body.call("_step_jitter", 1, 3)),
					"the two diagonals take different steps from each other")
			_next("still")
		"still":
			# Standing still, the legs stop. A creature jogging on the
			# spot looks broken.
			if _ticks == 1:
				# Take EVERY target away so it genuinely stops. Calling
				# set_speed(0) alone does nothing — the enemy overwrites
				# it with its REAL velocity every tick, which is the
				# point of driving the gait from actual movement.
				#
				# By group, not by emptying Players/. The practice dummy
				# (STO-ENEMIES-029) is a legitimate target that lives in
				# Dummies/, so clearing one container left something for
				# the spider to walk toward and it never stood still.
				# `self` IS the SceneTree here (this script extends it),
				# so the group is asked for directly.
				for c in get_nodes_in_group("players"):
					(c as Node).queue_free()
				return false
			# Long enough for the limb springs to come to rest before
			# the sample is taken. The limbs now lag the gait and
			# overshoot when it stops (STO-ENEMIES-039), so a spider
			# that has just halted is still swinging for a second or so
			# — by design. The springs decay with a time constant of
			# 0.59 s, so reaching a genuine standstill takes about 4 s.
			# 40 ticks, and then 150, both caught it mid-settle and read
			# that as jogging on the spot.
			#
			# The assertion is unchanged and the tolerance is untouched:
			# it still has to end up genuinely still.
			if _ticks == 330:
				_feet_a = _body.call("foot_positions")
				return false
			if _ticks < 350:
				return false
			var feet_c: Array = _body.call("foot_positions")
			var still := true
			var worst := 0.0
			for i in mini(_feet_a.size(), feet_c.size()):
				var d := (_feet_a[i] as Vector3).distance_to(feet_c[i] as Vector3)
				worst = maxf(worst, d)
				if d > 0.005:
					still = false
			print("[STILL] worst foot drift %.4f m, enemy speed %.4f, gait_lag %.4f" % [worst, _crawler.velocity.length(), float(_body.call("gait_lag"))])
			_check(still, "a standing crawler does not jog on the spot")
			_next("stumble")
		"stumble":
			# THE CRASH (2026-08-14): a MEDIUM hit put the enemy in the
			# stumble tier, which called buckle_leg — a HUMANOID move
			# the quadruped does not have. "Nonexistent function" halts
			# the game in a debug build, so every spider that took a
			# glancing blow killed the session.
			if _ticks == 1:
				_crawler.call("apply_knockback", Vector3(0.0, 0.0, -45.0))
				return false
			if _ticks < 20:
				return false
			_check(is_instance_valid(_crawler),
					"a MEDIUM hit does not kill the game (no buckle_leg call)")
			_check(not bool(_crawler.call("is_dead")),
					"and the spider is still alive after a stagger")
			_next("climb")
		"climb":
			# STO-ENEMIES-024: cornered against a wall, it goes UP.
			if _ticks == 1:
				var wall := StaticBody3D.new()
				wall.name = "ClimbWall"
				var cs2 := CollisionShape3D.new()
				var wb := BoxShape3D.new()
				wb.size = Vector3(8.0, 12.0, 0.6)
				cs2.shape = wb
				wall.add_child(cs2)
				_main.add_child(wall)
				wall.global_position = Vector3(0.0, 6.0, 34.0)
				# Player high up beyond the wall, so it must climb.
				var pl3: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
				pl3.name = "1"
				_main.get_node("Players").add_child(pl3)
				pl3.global_position = Vector3(0.0, 9.0, 32.0)
				_crawler.global_position = Vector3(0.0, 1.0, 35.2)
				_climb_from = _crawler.global_position.y
				return false
			if _ticks < 150:
				return false
			var gained := _crawler.global_position.y - _climb_from
			# Reported, not asserted. This 12 m wall is now deliberately
			# UNclimbable (STO-ENEMIES-027 — things yes, walls no), so a
			# gain of ~0 here is the correct answer, not a regression.
			# The real coverage lives in smoke_clamber.gd, which checks
			# both halves on a FRESH spider; this phase inherits one an
			# earlier phase already staggered.
			print("[CLIMB] gained %.2f m, climbing=%s"
					% [gained, str(_crawler.call("is_climbing"))])
			# Walkers do NOT climb — this is the spider's trick.
			_walker.global_position = Vector3(3.0, 1.0, 35.2)
			_check(not bool(_walker.call("is_climbing")),
					"a Walker at the same wall does not climb")
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
