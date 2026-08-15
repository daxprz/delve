extends SceneTree
## Smoke test for the spider's mind.
##   godot --headless -s res://tests/smoke_spider_mind.gd
##
##   STO-ENEMIES-038  senses you by hitbox, and REMEMBERS where you were
##   STO-ENEMIES-043  practises its own walk, from one that already works
##   STO-ENEMIES-044  copes when it is getting nowhere
##   STO-ENEMIES-045  remembers you forever, across a restart
##   STO-ENEMIES-046  learns which way you break, where you hide, who you are
##   STO-ENEMIES-047  picks a plan, prefers what works, still makes mistakes
##
## The epic asks for one thing specifically, and it is the rule this
## whole file is built around:
##
## > each one measured against a spider that has NOT learned, so "it did
## > something" cannot pass for "it learned something".
##
## So every learning check here runs TWO minds side by side — one that
## watched a player, one that watched nobody — and compares them. A
## check on the taught mind alone would pass just as happily if the
## numbers were hard-coded.

const MIND := "res://scripts/spider_mind.gd"
const SAVE_PATH := "user://test_spider_memory.json"

var _failures := 0
var _ticks := 0
var _phase := "sense"
var _world: Node3D
var _mind
var _blank
var _runner: Node3D


func _make_mind(seed_value: int):
	return (load(MIND) as GDScript).new(seed_value)


func _physics_process(delta: float) -> bool:
	_ticks += 1
	match _phase:
		"sense":
			if _ticks == 1:
				_world = Node3D.new()
				root.add_child(_world)
				# A body in the players group, and nothing else.
				var p := CharacterBody3D.new()
				p.name = "Prey"
				p.add_to_group("players")
				var cs := CollisionShape3D.new()
				var cap := CapsuleShape3D.new()
				cap.radius = 0.4
				cap.height = 1.6
				cs.shape = cap
				p.add_child(cs)
				_world.add_child(p)
				p.global_position = Vector3(6.0, 0.0, 0.0)
				_runner = p
				_mind = _make_mind(7)
				return false
			if _ticks < 5:
				return false
			var found = _mind.sense(_world.get_world_3d(), Vector3.ZERO,
					RID())
			_check(found == _runner,
					"it FEELS for you and finds you (%s)"
					% (found.name if found != null else "nobody"))
			_check(_mind.hunting_memory(),
					"and writes down where you were")
			_check(_mind.last_known().distance_to(Vector3(6.0, 0.0, 0.0)) < 1.0,
					"in the right place (%.1f, %.1f)"
					% [_mind.last_known().x, _mind.last_known().z])
			_next("far")

		"far":
			# Out of range: it must find nothing, and it must NOT
			# forget. This is the whole story — losing you has to be a
			# thing you can do, and it has to keep coming anyway.
			_runner.global_position = Vector3(400.0, 0.0, 0.0)
			if _ticks < 5:
				return false
			var found = _mind.sense(_world.get_world_3d(), Vector3.ZERO,
					RID())
			_check(found == null,
					"walk far enough away and it cannot feel you any more")
			_check(_mind.hunting_memory(),
					"but it does NOT forget — it still has your last place")
			print("[MIND] lost the player, still hunting %.1f, %.1f"
					% [_mind.last_known().x, _mind.last_known().z])
			# Arriving there and finding nobody: the trail goes cold.
			_check(_mind.reached_memory(_mind.last_known()),
					"standing on the remembered spot counts as arriving")
			_mind.trail_cold()
			_check(not _mind.hunting_memory(),
					"and finding nothing there, the trail goes cold")
			_next("watch")

		"watch":
			_taught_vs_blank()
			_next("places")

		"places":
			_check(_mind.favourite_place("Runner")
					.distance_to(Vector3(31.0, 0.0, 31.0)) < 6.0,
					"it learns WHERE you like to be (%.0f, %.0f)"
					% [_mind.favourite_place("Runner").x,
					_mind.favourite_place("Runner").z])
			_check(_blank.favourite_place("Runner") == Vector3.ZERO,
					"a spider that watched nobody has no idea where you go")
			_check(_mind.character_of("Runner") == "",
					"it only knows what it could actually see")
			_next("plans")

		"plans":
			# One choice can never show a preference. Count many.
			var taught = _make_mind(11)
			for i in 40:
				taught.note_outcome("Runner", "cut_off", true)
			var picked := 0
			var mistakes_seen := 0
			for i in 400:
				if taught.choose_plan("Runner") == "cut_off":
					picked += 1
			mistakes_seen = taught.mistakes()
			var share := float(picked) / 400.0
			print("[MIND] picked the winning plan %d/400 (%.0f%%), "
					% [picked, share * 100.0]
					+ "made %d mistakes" % mistakes_seen)
			_check(share > 0.5,
					"it PREFERS the plan that has worked (%.0f%%)"
					% (share * 100.0))
			_check(share < 0.95,
					"but never always — it can still be baited (%.0f%%)"
					% (share * 100.0))
			_check(mistakes_seen > 0,
					"it makes real mistakes (%d in 400)" % mistakes_seen)
			# A fresh mind must have no favourite at all.
			var fresh = _make_mind(11)
			var fresh_picked := 0
			for i in 400:
				if fresh.choose_plan("Runner") == "cut_off":
					fresh_picked += 1
			print("[MIND] a spider that has never met you picks it %d/400"
					% fresh_picked)
			_check(fresh_picked < picked,
					"and a spider that has never met you has no preference "
					+ "(%d vs %d)" % [fresh_picked, picked])
			_next("practise")

		"practise":
			var walker = _make_mind(3)
			var start: float = walker.gait()
			_check(is_equal_approx(start, 1.0),
					"it starts with the walk it always had, not a random one")
			# Walk it: good distance while the gait is long, poor while
			# short, so there is something real to hill-climb toward.
			for i in 4000:
				walker.practise(walker.gait() * 0.05, 0.05)
			print("[MIND] after %d attempts, stride %.3f (best %.3f)"
					% [walker.tries(), walker.gait(), walker.best_gait()])
			_check(walker.tries() > 5,
					"it keeps trying (%d attempts)" % walker.tries())
			_check(not is_equal_approx(walker.best_gait(), start),
					"and its walk really changes (%.3f -> %.3f)"
					% [start, walker.best_gait()])
			_check(walker.best_gait() > start,
					"toward the one that covers more ground (%.3f)"
					% walker.best_gait())
			_check(walker.gait() >= 0.75 and walker.gait() <= 1.35,
					"and never practises itself into being unable to walk")
			_next("stuck")

		"stuck":
			var stuck = _make_mind(5)
			for i in 200:
				stuck.note_progress(0.0, 1.0 / 60.0, true)
				if stuck.is_detouring():
					break
			_check(stuck.is_detouring(),
					"getting nowhere, it tries a different way")
			var fine = _make_mind(5)
			for i in 200:
				fine.note_progress(0.2, 1.0 / 60.0, true)
			_check(not fine.is_detouring(),
					"and one that IS getting somewhere carries straight on")
			# Standing still ON PURPOSE is not being stuck. Without this
			# the spider wandered off mid-grab to "try something else",
			# because holding you still to smash you into the ground
			# looks exactly like failing to move.
			var waiting = _make_mind(5)
			for i in 600:
				waiting.note_progress(0.0, 1.0 / 60.0, false)
			_check(not waiting.is_detouring(),
					"and one deliberately standing still is NOT stuck")
			_next("forever")

		"forever":
			# Save, throw it all away, load it back.
			var before: float = _mind.break_bias("Runner")
			var knew: int = _mind.knows("Runner")
			_check(_mind.save_memory(SAVE_PATH), "it writes down what it knows")
			var reborn = _make_mind(7)
			_check(reborn.knows("Runner") == 0,
					"a brand-new spider knows nothing about you")
			_check(reborn.load_memory(SAVE_PATH),
					"and can read the memory back")
			print("[MIND] before %d observations, after reload %d"
					% [knew, reborn.knows("Runner")])
			_check(reborn.knows("Runner") == knew,
					"it remembers you across a restart (%d observations)"
					% reborn.knows("Runner"))
			_check(absf(reborn.break_bias("Runner") - before) < 0.001,
					"including which way you break")
			# A missing file must be survivable, not fatal.
			var lost = _make_mind(7)
			_check(not lost.load_memory("user://no_such_file_at_all.json"),
					"a missing memory file is survivable")
			_check(lost.knows("Runner") == 0, "and leaves it blank")
			DirAccess.remove_absolute(ProjectSettings
					.globalize_path(SAVE_PATH))
			return _finish()
	return false


## The load-bearing comparison: one mind that watched a player who
## always breaks the same way, one that watched nobody.
func _taught_vs_blank() -> void:
	_blank = _make_mind(7)
	var mover := Node3D.new()
	mover.name = "Runner"
	_world.add_child(mover)

	# A player who ALWAYS breaks the same way, seen from a spider
	# standing at the origin: they run across its line of sight, in the
	# same direction, over and over. That is what "they always go left"
	# means — it is only meaningful relative to whoever is watching.
	var eye := Vector3.ZERO
	for i in 200:
		mover.global_position = Vector3(12.0, 0.0, -20.0 + float(i) * 0.2)
		_mind.watch(mover, 1.0, eye)   # delta big enough to sample each call
	# And they hole up in one corner far more than anywhere else.
	for i in 120:
		mover.global_position = Vector3(31.0, 0.0, 31.0)
		_mind.watch(mover, 1.0, eye)

	print("[MIND] taught: %d observations, break bias %.3f"
			% [_mind.knows("Runner"), _mind.break_bias("Runner")])
	print("[MIND] blank:  %d observations, break bias %.3f"
			% [_blank.knows("Runner"), _blank.break_bias("Runner")])
	_check(_mind.knows("Runner") > 50,
			"it watches you and keeps count (%d observations)"
			% _mind.knows("Runner"))
	_check(_blank.knows("Runner") == 0,
			"a spider that watched nobody has learned nothing")

	var taught_aim: Vector3 = _mind.aim_at(mover)
	var blank_aim: Vector3 = _blank.aim_at(mover)
	var lead := taught_aim.distance_to(mover.global_position)
	print("[MIND] taught aims %.2f m off you; blank aims %.2f m off"
			% [lead, blank_aim.distance_to(mover.global_position)])
	_check(blank_aim.distance_to(mover.global_position) < 0.01,
			"a spider that has learned nothing aims straight AT you")
	_check(lead > 0.5,
			"one that has watched you aims where you are GOING — %.2f m "
			% lead + "ahead. It stops chasing and starts cutting you off")


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
