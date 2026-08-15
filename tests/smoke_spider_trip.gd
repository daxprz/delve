extends SceneTree
## Smoke test for STO-ENEMIES-056 — something hits its legs, it
## stumbles.
##   godot --headless -s res://tests/smoke_spider_trip.gd
##
## The hard part of this feature is NOT noticing a collision. It is
## telling a knock from the floor: a spider's feet are touching the
## ground every moment it stands, so a naive version stumbles for ever
## and never walks anywhere.
##
## So the load-bearing check is the NEGATIVE one, and it runs first: a
## spider walking across open ground, feet hitting the floor hundreds of
## times, must NOT stumble even once. Only then does a wall in its path
## count for anything.

const ENEMY_SCENE := "res://scenes/enemy.tscn"
const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _walking_knocks := 0
var _before := Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				# A world of our OWN, not main.tscn.
				#
				# main.tscn ships a 71-wall procedural maze, so "walking
				# across open ground" was nothing of the sort — the
				# spider met real obstacles and reported four perfectly
				# correct knocks, and the negative check called them
				# false positives.
				_main = Node3D.new()
				_main.name = "TripWorld"
				root.add_child(_main)
				var holder := Node3D.new()
				holder.name = "Enemies"
				_main.add_child(holder)
				var ground := StaticBody3D.new()
				ground.name = "Ground"
				var gcs := CollisionShape3D.new()
				var gbx := BoxShape3D.new()
				gbx.size = Vector3(120.0, 2.0, 120.0)
				gcs.shape = gbx
				ground.add_child(gcs)
				_main.add_child(ground)
				ground.global_position = Vector3(0.0, -1.0, 0.0)
				# Something to walk toward, and nothing else at all.
				var prey := CharacterBody3D.new()
				prey.name = "Bait"
				prey.add_to_group("players")
				var pcs := CollisionShape3D.new()
				var pcap := CapsuleShape3D.new()
				pcap.radius = 0.4
				pcap.height = 1.6
				pcs.shape = pcap
				prey.add_child(pcs)
				_main.add_child(prey)
				prey.global_position = Vector3(0.0, 1.0, -22.0)
				var e: CharacterBody3D = (load(ENEMY_SCENE)
						as PackedScene).instantiate()
				e.name = "Subject"
				e.set("kind", EnemyKinds.index_of("crawler"))
				_main.get_node("Enemies").add_child(e)
				e.global_position = Vector3(0.0, 1.0, 8.0)
				_spider = e
				return false
			if _ticks < 40:
				return false
			_check(_spider.has_method("leg_knocks"),
					"the spider notices things hitting its legs")
			_check(_spider.call("solid") != null,
					"and has real physics legs for them to hit")
			_next("open_ground")

		"open_ground":
			# THE check. Walking on flat, empty floor, its feet strike
			# the ground constantly — and none of that is a knock.
			if _ticks < 300:
				return false
			_walking_knocks = int(_spider.call("leg_knocks"))
			print("[TRIP] walked 300 ticks across open floor: %d knocks"
					% _walking_knocks)
			_check(_walking_knocks == 0,
					"walking on open ground does NOT trip it (%d) — the "
					% _walking_knocks + "floor is not an obstacle")
			_next("wall")

		"wall":
			# Now put something in the way of its legs.
			if _ticks == 1:
				var b := StaticBody3D.new()
				b.name = "Obstacle"
				var cs := CollisionShape3D.new()
				var bx := BoxShape3D.new()
				# Ten metres, not three. The spider CLAMBERS over anything
				# up to its own body height (STO-ENEMIES-027), so a 3 m
				# obstacle is something it climbs, not something that
				# catches its legs — and the test read that as the
				# feature not working.
				bx.size = Vector3(24.0, 10.0, 1.0)
				cs.shape = bx
				b.add_child(cs)
				_main.add_child(b)
				# Just ahead of it, tall enough to catch a leg.
				b.global_position = _spider.global_position \
						+ Vector3(0.0, 4.0, -4.0)
				return false
			# Long enough for several gait cycles against the wall.
			# At 420 ticks whether a leg caught it depended on which
			# part of its stride it arrived in, and the test came out
			# 0, 2, 0 across three runs. A flaky test is worse than a
			# failing one — it teaches you to ignore red.
			if _ticks < 900:
				return false
			var total := int(_spider.call("leg_knocks"))
			var from_wall := total - _walking_knocks
			print("[TRIP] after meeting the obstacle: %d knocks (%d from "
					% [total, from_wall] + "the obstacle)")
			_check(from_wall > 0,
					"something in the way DOES trip it (%d knocks)"
					% from_wall)
			_next("recovers")

		"recovers":
			# NOT "does it keep moving". It is pressed against a
			# ten-metre wall it is supposed to be stopped by, so
			# measuring travel there measured the wall working and
			# called it a stumble that never ended — it came out
			# 0.21 / 0.39 / 0.54 / 0.13 m across runs, passing and
			# failing on nothing.
			#
			# The real requirement is that a leg resting against a wall
			# does not stumble it EVERY TICK. One knock per frame would
			# be a creature frozen in a permanent lurch, and the
			# cooldown is the thing that stops it.
			if _ticks < 300:
				return false
			var knocks := int(_spider.call("leg_knocks"))
			var per_tick := float(knocks) / 1200.0
			print("[TRIP] %d knocks over 1200 ticks pressed against it "
					% knocks + "(%.3f per tick)" % per_tick)
			_check(per_tick < 0.05,
					"a leg resting on a wall does not stumble it every "
					+ "tick (%.3f per tick) — it lurches and recovers"
					% per_tick)
			_check(not bool(_spider.call("is_climbing")),
					"and it has not climbed the wall")
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
