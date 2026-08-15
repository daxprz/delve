extends SceneTree
## Smoke test for STO-ENEMIES-057 — the giant spider really stumbles.
##   godot --headless -s res://tests/smoke_spider_stumble.gd
##
## Three things have to be true at once, and they pull against each
## other, which is why all three are measured rather than one:
##
##   1. A hit the game can actually deliver trips it.
##   2. It is STILL much harder to trip than a Walker.
##   3. Knocking it DOWN is no easier than it was.
##
## Number 3 is the one that would be quietly ruined by fixing 1. Making
## a towering monster easy to trip is fine; making it easy to fell turns
## it into a pushover, and nothing about the stumble check would notice.

const ENEMY_SCENE := "res://scenes/enemy.tscn"
const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

## Impulses, not "strengths". What decides the tier is dv = impulse /
## mass, and the giant spider masses about 3.1 — so an impulse of 32
## delivers dv 10, which is well past the trip threshold (4.05) and
## well under the knockdown one (24).
##
## The first version of this test multiplied its numbers by 3 and
## delivered dv 25, which is a KNOCKDOWN. It then reported that the
## spider does not stumble, when what had actually happened was that it
## had been floored.
const TRIP_IMPULSE := 32.0
## Hard, but still under what should fell it.
##
## The giant spider masses 2.17, not the 3.1 first assumed, so knockdown
## begins at 24 x 2.17 = 52. At 62 the test was delivering dv 28.5 — a
## genuine knockdown — and then complaining that the spider had been
## knocked down. 44 gives dv 20, hard but not fatal to its footing.
const HARD_IMPULSE := 44.0
## A tap: enough to rock a Walker, not a giant.
const TAP_WALKER := 3.6
const TAP_SPIDER := 10.0

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _walker: CharacterBody3D
var _lean := 0.0
var _stumbled_for := 0


func _spawn(kind_id: String, nm: String, at: Vector3) -> CharacterBody3D:
	var e: CharacterBody3D = (load(ENEMY_SCENE) as PackedScene).instantiate()
	e.name = nm
	e.set("kind", EnemyKinds.index_of(kind_id))
	_main.get_node("Enemies").add_child(e)
	e.global_position = at
	return e


## How far the creature's body is leaning right now, in radians.
func _body_lean(who: Node) -> float:
	var b := who.get_node_or_null("Body") as Node3D
	if b == null:
		return 0.0
	return b.transform.basis.get_rotation_quaternion().get_angle()


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				_spider = _spawn("crawler", "Giant", Vector3(0.0, 1.0, 4.0))
				_walker = _spawn("walker", "Small", Vector3(9.0, 1.0, 4.0))
				return false
			if _ticks < 60:
				return false
			for e in _main.get_node("Enemies").get_children():
				if e != _spider and e != _walker:
					(e as Node3D).global_position = Vector3(0, 0, 700)
			_check(_spider != null and _walker != null,
					"a giant spider and a Walker to compare it with")
			_next("trip_spider")

		"trip_spider":
			# A blow a player can actually land.
			if _ticks == 1:
				_spider.call("apply_knockback",
						Vector3(1.0, 0.0, 0.0) * TRIP_IMPULSE)
				return false
			_lean = maxf(_lean, _body_lean(_spider))
			if _ticks < 120:
				return false
			print("[LURCH] impulse %.0f leaned the giant spider %.3f rad "
					% [TRIP_IMPULSE, _lean] + "(%.1f deg)"
					% rad_to_deg(_lean))
			_check(_lean > 0.15,
					"a hit the game can deliver really trips it (%.1f deg)"
					% rad_to_deg(_lean))
			# Bigger than the old 12.6 degrees, which was the whole
			# complaint.
			_check(rad_to_deg(_lean) > 20.0,
					"and the lurch is BIG — %.1f deg, against the 12.6 it "
					% rad_to_deg(_lean) + "used to manage")
			_next("still_tough")

		"still_tough":
			# It must still be much harder to trip than a Walker. A
			# small hit that visibly rocks a Walker should barely
			# trouble it.
			if _ticks == 1:
				_spider.call("apply_knockback",
						Vector3(1.0, 0.0, 0.0) * TAP_SPIDER)
				_walker.call("apply_knockback",
						Vector3(1.0, 0.0, 0.0) * TAP_WALKER)
				_lean = 0.0
				return false
			if _ticks < 90:
				return false
			var spider_lean := _body_lean(_spider)
			var walker_lean := _body_lean(_walker)
			print("[LURCH] a small hit: Walker leaned %.1f deg, giant "
					% rad_to_deg(walker_lean) + "spider %.1f deg"
					% rad_to_deg(spider_lean))
			_check(walker_lean > spider_lean,
					"a tap that rocks a Walker still barely troubles the "
					+ "giant (%.1f deg vs %.1f deg) — it is easier to trip "
					% [rad_to_deg(walker_lean), rad_to_deg(spider_lean)]
					+ "than before, not easy")
			_next("not_easier_to_fell")

		"not_easier_to_fell":
			# The check that fixing the stumble could silently ruin.
			if _ticks == 1:
				# Hard enough to floor a Walker several times over, but
				# under what a giant spider should need.
				_spider.call("apply_knockback",
						Vector3(1.0, 0.2, 0.0) * HARD_IMPULSE)
				return false
			if _ticks < 60:
				return false
			var down: bool = _spider.get_parent() \
					.get_node_or_null("GiantRagdoll") != null
			print("[LURCH] an impulse of %.0f put it down: %s"
					% [HARD_IMPULSE, str(down)])
			_check(not down,
					"a blow that stumbles it does NOT knock it down — "
					+ "tripping and toppling stay different tiers")
			_next("recovers")

		"recovers":
			if _ticks < 200:
				return false
			var lean := _body_lean(_spider)
			print("[LURCH] settled back to %.2f deg" % rad_to_deg(lean))
			_check(rad_to_deg(lean) < 5.0,
					"and it gathers itself back up (%.2f deg)"
					% rad_to_deg(lean))
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
