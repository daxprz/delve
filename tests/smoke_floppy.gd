extends SceneTree
## Smoke test for STO-ENEMIES-037 — floppy legs and pincers.
##   godot --headless -s res://tests/smoke_floppy.gd
##
## The trap here is the same one that nearly shipped in STO-ENEMIES-030:
## the spider WALKS, so anything measured in world space moves whether
## the limbs flop or not. Everything below is measured in the
## creature's own frame, and the still-spider case is checked first so
## that "it moved" cannot pass for "it flopped".

const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _body: Node3D
var _still_flop := 0.0
var _moved_flop := 0.0
var _rest: Array = []


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 3:
				if _ticks == 1:
					_main = load("res://scenes/main.tscn").instantiate()
					root.add_child(_main)
				return false
			# No players at all, so nothing pulls the spider about and
			# the still case is genuinely still.
			for p in get_nodes_in_group("players"):
				(p as Node).queue_free()
			var e: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
			e.name = "S1"
			e.set("kind", EnemyKinds.index_of("crawler"))
			_main.get_node("Enemies").add_child(e)
			e.global_position = Vector3(0.0, 1.0, 45.0)
			_spider = e
			_next("api")

		"api":
			if _ticks < 5:
				return false
			_body = _spider.get_node_or_null("Body")
			_check(_body != null and _body.has_method("flop"),
					"the spider's body has floppy limbs")
			if _body == null or not _body.has_method("flop"):
				return _finish()
			_next("still")

		"still":
			# A standing spider's legs must be STILL. This is the check
			# that gives every other one its meaning.
			if _ticks < 60:
				return false
			_still_flop = (_body.call("flop") as Vector2).length()
			_rest = _leg_angles()
			print("[FLOP] standing still: lag %.4f rad" % _still_flop)
			_check(_still_flop < 0.02,
					"a standing spider's limbs are still (%.4f)" % _still_flop)
			_next("shove")

		"shove":
			# Now yank it sideways. Acceleration is what limbs lag
			# behind, so a shove is exactly the right provocation.
			# Driven by VELOCITY, not by apply_knockback. A knockback big
			# enough to lurch the creature is also big enough to ragdoll
			# it (dv 40 against a threshold of 7.5) — and a ragdolled
			# enemy has its velocity zeroed every tick, so the first
			# version of this phase measured a spider lying perfectly
			# still and reported 0.0098 rad of "trail".
			if _ticks < 12:
				_spider.velocity = Vector3(14.0, 0.0, 0.0)
				if _ticks > 1:
					_moved_flop = maxf(_moved_flop,
							(_body.call("flop") as Vector2).length())
				return false
			_check(_spider.get_parent().get_node_or_null("S1Ragdoll") == null,
					"the shove lurched it without knocking it down")
			var swung := _angle_change()
			print("[FLOP] after a shove: lag %.4f rad, joints moved %.4f rad"
					% [_moved_flop, swung])
			_check(_moved_flop > _still_flop + 0.02,
					"being thrown about makes the limbs trail (%.4f vs %.4f)"
					% [_moved_flop, _still_flop])
			_check(swung > 0.01,
					"and the joints actually swing with it (%.4f rad)" % swung)
			_next("settle")

		"settle":
			# It has to come back. A spring that never returns is a
			# broken pose, not floppiness.
			#
			# The creature is brought to a genuine stop first. Left to
			# coast, friction bleeds its speed off at a steady rate —
			# which IS a change in velocity, so the limbs correctly kept
			# trailing and "settled" read higher than the shove itself.
			# A decelerating spider is not a settled one.
			if _ticks == 1:
				_spider.velocity = Vector3.ZERO
				return false
			if _ticks < 150:
				return false
			var now := (_body.call("flop") as Vector2).length()
			print("[FLOP] settled back to %.4f rad" % now)
			_check(now < _moved_flop * 0.6,
					"and they settle back down (%.4f -> %.4f)"
					% [_moved_flop, now])
			_next("limp")

		"limp":
			# A hit knocks the life out of them.
			if _ticks == 1:
				_body.call("go_limp", 0.6)
				return false
			if _ticks == 2:
				_check(float(_body.call("limpness")) > 0.5,
						"a hit makes the limbs go limp (%.2f)"
						% float(_body.call("limpness")))
				# The arms hang too, not just the legs.
				var p: Node3D = _body.call("pincers")
				_check(p != null and float(p.call("limpness")) > 0.5,
						"and the pincer arms hang as well")
				return false
			if _ticks < 90:
				return false
			_check(float(_body.call("limpness")) < 0.05,
					"then it gathers itself back up (%.2f)"
					% float(_body.call("limpness")))
			_next("alive")

		"alive":
			# Floppiness must not cost the spider its gait or its
			# ability to be knocked down.
			if _ticks == 1:
				_spider.call("apply_knockback", Vector3(0.0, 2.0, 12.0) * 60.0)
				return false
			if _ticks < 12:
				return false
			_check(_spider.get_parent().get_node_or_null("S1Ragdoll") != null,
					"a floppy spider still ragdolls when hit hard")
			return _finish()
	return false


## Every driven joint angle, in the creature's OWN frame — never world
## space, which moves when the spider merely walks.
func _leg_angles() -> Array:
	var out: Array = []
	for nm in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var root := _body.get_node_or_null(nm)
		if root == null:
			continue
		var up := root.get_node_or_null("Upper") as Node3D
		if up != null:
			out.append(up.rotation)
		var lo := up.get_node_or_null("Lower") as Node3D if up != null else null
		if lo != null:
			out.append(lo.rotation)
	return out


func _angle_change() -> float:
	var now := _leg_angles()
	var worst := 0.0
	for i in mini(_rest.size(), now.size()):
		worst = maxf(worst, (_rest[i] as Vector3).distance_to(now[i] as Vector3))
	return worst


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
