extends SceneTree
## Smoke test for STO-ENEMIES-030 — the spider's pincer arms.
##   godot --headless -s res://tests/smoke_pincers.gd
##
## The arms are the limb every later story in this epic needs: the
## grabbing, the carrying, the impaling all act through them. So what
## matters here is not that two shapes exist but that they have real
## reach, that they MOVE, and that adding them did not quietly break
## the creature that carries them.

const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _walker: CharacterBody3D
var _body: Node3D
var _pincers: Node3D
var _tips_a: Array = []
var _reach := 0.0


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
			if _ticks < 3:
				if _ticks == 1:
					_main = load("res://scenes/main.tscn").instantiate()
					root.add_child(_main)
				return false
			_spider = _spawn(EnemyKinds.index_of("crawler"), "S1",
					Vector3(0.0, 1.0, 40.0))
			_walker = _spawn(EnemyKinds.index_of("walker"), "W1",
					Vector3(4.0, 1.0, 40.0))
			_next("built")

		"built":
			if _ticks < 5:
				return false
			_body = _spider.get_node_or_null("Body")
			_check(_body != null, "the spider has a body")
			if _body == null:
				return _finish()
			_check(_body.has_method("pincers"), "the body knows about pincers")
			_pincers = _body.call("pincers")
			_check(_pincers != null, "the spider grew pincer arms")
			if _pincers == null:
				return _finish()
			_check(int(_pincers.call("arm_count")) == 2,
					"there are exactly two arms (%d)"
					% int(_pincers.call("arm_count")))

			# Reach is the point of an arm. Compared against the body it
			# hangs off, not a number typed in here — an arm that cannot
			# get past the creature it is bolted to is decoration.
			_reach = float(_pincers.call("reach"))
			var body_w := float(_body.call("body_size").x)
			print("[PINCERS] reach %.2f m vs body width %.2f m"
					% [_reach, body_w])
			_check(_reach > body_w * 2.0,
					"they reach well past the body (%.2f vs %.2f m)"
					% [_reach, body_w])

			# Two arms with two halves each: four jaw parts and two tips.
			var tip_l: Vector3 = _pincers.call("tip_position", 0)
			var tip_r: Vector3 = _pincers.call("tip_position", 1)
			_check(tip_l.distance_to(tip_r) > 0.1,
					"the two arms are in different places (%.2f m apart)"
					% tip_l.distance_to(tip_r))
			_next("jaws")

		"jaws":
			# Open and shut on demand — this is the handle every later
			# story in the epic reaches for.
			if _ticks == 1:
				_pincers.call("set_jaw", 1.0)
				return false
			if _ticks < 30:
				return false
			var wide := float(_pincers.call("jaw"))
			_pincers.call("set_jaw", 0.0)
			print("[PINCERS] jaw opened to %.2f" % wide)
			_check(wide > 0.8, "the pincers open on demand (%.2f)" % wide)
			_next("shut")

		"shut":
			if _ticks < 30:
				return false
			var shut := float(_pincers.call("jaw"))
			print("[PINCERS] jaw closed to %.2f" % shut)
			_check(shut < 0.2, "and shut again (%.2f)" % shut)
			# Hand them back to their idle weave for the next phase.
			_pincers.call("set_jaw", -1.0)
			_next("weave")

		"weave":
			# "They move on their own" is in the DoD, so it is asserted
			# rather than assumed. Frozen arms would look finished in a
			# screenshot and be obviously wrong in motion.
			# Measured RELATIVE TO THE CREATURE, not in world space. The
			# spider walks, so a world-space tip moves metres per second
			# whether the arms do anything or not — the first version of
			# this check reported 1.318 m of "weave" and would have
			# passed with the arms welded solid.
			if _ticks == 1:
				_tips_a = [_local_tip(0), _local_tip(1)]
				return false
			if _ticks < 45:
				return false
			var moved := 0.0
			for i in 2:
				moved = maxf(moved, (_tips_a[i] as Vector3).distance_to(_local_tip(i)))
			print("[PINCERS] tips moved %.3f m while idle" % moved)
			_check(moved > 0.02,
					"the arms weave on their own (%.3f m)" % moved)
			_next("walker")

		"walker":
			# The Walker is not this creature. Pincers are the spider's.
			var wbody := _walker.get_node_or_null("Body")
			var walker_has: bool = wbody != null \
					and wbody.has_method("pincers") \
					and wbody.call("pincers") != null
			_check(not walker_has, "a Walker grows no pincers")
			_next("intact")

		"intact":
			# Adding limbs must not break the creature carrying them.
			# The spider's gait, its clambering and its ragdoll all
			# live in the same body node these arms were bolted onto.
			if _ticks == 1:
				_spider.call("apply_knockback", Vector3(0.0, 2.0, 12.0) * 60.0)
				return false
			if _ticks < 12:
				return false
			var rag := _spider.get_parent().get_node_or_null("S1Ragdoll")
			_check(rag != null, "a spider with arms still ragdolls")
			return _finish()
	return false


## Where a pincer tip is relative to the creature carrying it, so that
## walking around does not read as arm movement.
func _local_tip(side_index: int) -> Vector3:
	var world: Vector3 = _pincers.call("tip_position", side_index)
	return _pincers.to_local(world)


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
