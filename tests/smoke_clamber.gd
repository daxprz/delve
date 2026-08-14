extends SceneTree
## Smoke test for STO-ENEMIES-027 — the spider clambers over things,
## but walls stop it.
##   godot --headless -s res://tests/smoke_clamber.gd
##
## The rule under test is a single question the creature asks of the
## world: can I see the top of this from here? A crate, yes — get over
## it. A ten-metre wall, no — go around.
##
## Both halves matter equally, and the second one is the half that is
## easy to fake. A spider that has simply had its climbing broken would
## pass "does not go up the wall" perfectly. So the crate case is
## checked FIRST, on the same creature: it must prove it still climbs
## before its refusal to climb the wall means anything at all.
##
## Every creature here is FRESH. The older climb check inherited a
## spider that an earlier phase had already staggered, which is why its
## height reading could not be trusted enough to assert on.

const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

const CRATE_TOP := 1.2      # a thing: well under the spider's reach
const WALL_TOP := 10.0      # a wall: far over it
const GROUND_Y := 1.0

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _walker: CharacterBody3D
var _from_y := 0.0
var _reach := 0.0
var _crate_gain := 0.0
var _saw_skirt := false
var _saw_climb := false
var _peak := -99.0


func _spawn(kind: int, nm: String, at: Vector3) -> CharacterBody3D:
	var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
	e.name = nm
	e.set("kind", kind)
	_main.get_node("Enemies").add_child(e)
	e.global_position = at
	return e


## A static box sitting ON the ground, `top` metres tall.
func _obstacle(nm: String, top: float, footprint: Vector3, at_xz: Vector2) -> void:
	var b := StaticBody3D.new()
	b.name = nm
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x, top, footprint.z)
	cs.shape = box
	b.add_child(cs)
	_main.add_child(b)
	b.global_position = Vector3(at_xz.x, top * 0.5, at_xz.y)


## Put a player just beyond the obstacle so the hunt runs into it.
func _prey(at: Vector3) -> void:
	for old in _main.get_node("Players").get_children():
		old.queue_free()
	var pl: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	pl.name = "1"
	_main.get_node("Players").add_child(pl)
	pl.global_position = at


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var ci := EnemyKinds.index_of("crawler")
			_check(ci >= 0, "the spider is a kind of enemy")
			if ci < 0:
				return _finish()
			_spider = _spawn(ci, "S1", Vector3(0.0, GROUND_Y, 42.0))
			_walker = _spawn(EnemyKinds.index_of("walker"), "W1",
					Vector3(6.0, GROUND_Y, 42.0))
			_next("measure")

		"measure":
			# The cut-off must come from the creature, not a number
			# someone typed. Read its body height and prove the
			# obstacles really do straddle it — otherwise this whole
			# test is measuring two cases that are secretly the same.
			if _ticks < 10:
				return false
			var body := _spider.get_node_or_null("Body")
			if body != null and body.has_method("body_height"):
				_reach = float(body.call("body_height"))
			print("[REACH] spider body height = %.2f m" % _reach)
			_check(_reach > 0.5, "the spider has a real measured reach (%.2f m)"
					% _reach)
			_check(CRATE_TOP < _reach,
					"the crate (%.1f m) is under that reach" % CRATE_TOP)
			_check(WALL_TOP > _reach,
					"the wall (%.1f m) is over it" % WALL_TOP)
			_next("crate")

		"crate":
			# --- IT GETS OVER A THING ---------------------------
			if _ticks == 1:
				_obstacle("Crate", CRATE_TOP, Vector3(4.0, 0.0, 1.0),
						Vector2(0.0, 39.0))
				_prey(Vector3(0.0, GROUND_Y, 36.0))
				_spider.global_position = Vector3(0.0, GROUND_Y, 41.0)
				_peak = -99.0
				return false
			# Let it fall to the floor and settle BEFORE taking the
			# baseline. Measured from the spawn height instead, the
			# drop of a spider placed a metre in the air is far bigger
			# than the climb and buries it completely.
			if _ticks == 25:
				_from_y = _spider.global_position.y
				return false
			if _ticks < 25:
				return false
			_peak = maxf(_peak, _spider.global_position.y)
			if bool(_spider.call("is_climbing")):
				_saw_climb = true
			if _ticks < 200:
				return false
			_crate_gain = _peak - _from_y
			print("[CRATE] settled %.2f, peak %.2f, gained %.2f m (top %.1f), ever-climbed=%s"
					% [_from_y, _peak, _crate_gain, CRATE_TOP, str(_saw_climb)])
			_check(_saw_climb, "the spider recognises a crate as climbable")
			_check(_crate_gain > 0.4,
					"and gets up over it (+%.2f m)" % _crate_gain)
			_next("wall")

		"wall":
			# --- BUT NOT OVER A WALL ----------------------------
			if _ticks == 1:
				_obstacle("BigWall", WALL_TOP, Vector3(14.0, 0.0, 1.0),
						Vector2(0.0, 19.0))
				_prey(Vector3(0.0, GROUND_Y, 16.0))
				_spider.global_position = Vector3(0.0, GROUND_Y, 21.0)
				_peak = -99.0
				return false
			if _ticks == 25:
				_from_y = _spider.global_position.y
				return false
			if _ticks < 25:
				return false
			if bool(_spider.call("is_skirting")):
				_saw_skirt = true
			_peak = maxf(_peak, _spider.global_position.y)
			if _ticks < 200:
				return false
			var gained := _peak - _from_y
			print("[WALL] gained %.2f m (top %.1f), climbing=%s, skirting=%s"
					% [gained, WALL_TOP, str(_spider.call("is_climbing")),
					str(_saw_skirt)])
			_check(gained < 0.4,
					"a wall stops it — no meaningful height gained (%.2f m)"
					% gained)
			_check(not bool(_spider.call("is_climbing")),
					"and it does not report climbing at a wall")
			# The two cases must genuinely differ, on the same creature.
			_check(_crate_gain - gained > 0.4,
					"crate and wall really are told apart (+%.2f vs +%.2f m)"
					% [_crate_gain, gained])
			_check(_saw_skirt,
					"blocked, it turns aside to go around the wall")
			_next("walker")

		"walker":
			# Clambering is the spider's trick, not everyone's.
			if _ticks == 1:
				_walker.global_position = Vector3(1.0, GROUND_Y, 21.0)
				return false
			if _ticks < 30:
				return false
			_check(not bool(_walker.call("is_climbing")),
					"a Walker at the same obstacle does not climb")
			_next("knockdown")

		"knockdown":
			# Getting over things must not make it un-killable.
			if _ticks == 1:
				_spider.call("apply_knockback", Vector3(0.0, 2.0, 12.0) * 60.0)
				return false
			if _ticks < 12:
				return false
			var rag := _spider.get_parent().get_node_or_null("S1Ragdoll")
			_check(rag != null,
					"a clambering spider still ragdolls when hit hard")
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
