extends SceneTree
## STO-ENEMIES-055 — is the spider SOLID?
##   godot --headless -s res://tests/smoke_spider_solid.gd
##
## This file exists to produce two numbers, and it was written BEFORE
## any attempt to make the spider solid, so the numbers it prints today
## are the baseline the attempt has to beat.
##
##   deepest  — how far the worst limb reaches INSIDE a wall
##   overlap  — how far the two worst legs pass THROUGH each other
##
## Two previous attempts at this (STO-ENEMIES-041) were reverted, and
## the thing that made the second one honest was exactly this: with
## collision on, deepest was 0.569 m; with it off, 0.568 m. The code
## ran and achieved nothing, and only the comparison showed it.
##
## So this test does not pass or fail on "it collides". It prints the
## measurements, and asserts only the things that must be true either
## way — that the spider is standing up, and that it is getting
## somewhere. A solid spider lying in a heap is not an improvement.

const ENEMY_SCENE := "res://scenes/enemy.tscn"
const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

## A slab for it to walk into. Wide and thick, so a limb that goes in
## has plainly gone in.
const SLAB_AT := Vector3(0.0, 2.0, -7.0)
const SLAB_SIZE := Vector3(14.0, 4.0, 1.2)

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _spider: CharacterBody3D
var _body: Node
var _deepest := 0.0
var _deepest_name := ""
var _overlap := 0.0
var _start := Vector3.ZERO
var _stand_min := 999.0
var _solid: Node
var _closest := 999.0
var _avoid_on := 0.0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				# A slab to walk into.
				var b := StaticBody3D.new()
				b.name = "Slab"
				var cs := CollisionShape3D.new()
				var bx := BoxShape3D.new()
				bx.size = SLAB_SIZE
				cs.shape = bx
				b.add_child(cs)
				_main.add_child(b)
				b.global_position = SLAB_AT
				# Our own spider, alone, walking at it.
				var e: CharacterBody3D = (load(ENEMY_SCENE)
						as PackedScene).instantiate()
				e.name = "Subject"
				e.set("kind", EnemyKinds.index_of("crawler"))
				_main.get_node("Enemies").add_child(e)
				e.global_position = Vector3(0.0, 1.0, -1.0)
				_spider = e
				return false
			if _ticks < 40:
				return false
			# Everything else out of the way, and one target BEHIND the
			# slab so it walks into it rather than wandering.
			for other in _main.get_node("Enemies").get_children():
				if other != _spider:
					(other as Node3D).global_position = Vector3(0, 0, 500)
			for p in get_nodes_in_group("players"):
				(p as Node3D).global_position = Vector3(0.0, 1.0, -20.0)
			_body = _spider.get_node_or_null("Body")
			_solid = _spider.call("solid") if _spider.has_method("solid") \
					else null
			print("[SOLID] physics bones present: %s"
					% ("yes, %d" % int(_solid.call("bone_count"))
					if _solid != null else "no — measuring the animation"))
			_check(_body != null and _body.has_method("limb_segments"),
					"the spider's limbs can be measured")
			if _body == null:
				return _finish()
			_start = _spider.global_position
			_next("walk")

		"walk":
			# Walk it into the slab and watch every limb, every tick.
			#
			# Measured off the PHYSICS bones when they exist, and only
			# off the animated chain when they do not. That distinction
			# is the whole test: the animated chain is what the gait
			# ASKED for, and asking is not the same as arriving. The
			# first run of this measured the plan and reported the
			# physics build as a 1 mm improvement, because the plan is
			# identical in both builds — it is the bones that differ.
			var segs: Array = (_solid.call("bone_segments")
					if _solid != null else _body.call("limb_segments"))
			for s in segs:
				var d := _into_slab(s["a"], s["b"], float(s["r"]))
				if d > _deepest:
					_deepest = d
					_deepest_name = String(s["name"])
			_overlap = maxf(_overlap, _worst_self_overlap(segs))
			# How CLOSE a limb ever got to the slab.
			#
			# Without this, "0.000 m inside the wall" is worthless: a
			# spider that walked round the wall and never touched it
			# would score a perfect zero. The claim is only meaningful
			# if the limbs actually met the thing they failed to enter.
			for s2 in segs:
				_closest = minf(_closest, _to_slab(s2["a"], s2["b"]))
			# How high the block is riding: a collapsed spider is not a
			# solid spider.
			_stand_min = minf(_stand_min,
					float(_body.call("body_height")) if _ticks > 60 else 999.0)
			if _ticks < 420:
				return false

			var travelled: float = _start.distance_to(
					_spider.global_position)
			print("")
			print("[SOLID] deepest limb inside the slab : %.3f m  (%s)"
					% [_deepest, _deepest_name])
			print("[SOLID] closest a limb came to the slab : %.3f m"
					% _closest)
			print("[SOLID] worst overlap between two legs: %.4f m"
					% _overlap)
			print("[SOLID] it travelled                  : %.2f m"
					% travelled)
			print("[SOLID] lowest the body rode          : %.2f m"
					% _stand_min)
			print("")

			# Only the things that must be true whatever happens.
			_check(travelled > 1.0,
					"it is getting somewhere (%.2f m) — a solid spider "
					% travelled + "that cannot walk is not an improvement")
			_check(_closest < 0.4,
					"the limbs really did MEET the slab (%.3f m) — without "
					% _closest + "this, '0 m inside' would just mean it "
					+ "walked round")
			_check(_stand_min > 0.5,
					"it is STANDING UP (body rode %.2f m) — a solid spider "
					% _stand_min + "lying in a heap is not an improvement")
			_avoid_on = _overlap
			_next("no_avoid")

		"no_avoid":
			# The SAME walk again, kept as a repeatability check.
			#
			# It was written to compare limb avoidance on against off
			# (STO-ENEMIES-062) and it earned its keep immediately: the
			# avoidance measured WORSE than no avoidance, and was
			# removed. What is left is a second run of the same course,
			# which is worth having anyway — it says how much of any
			# future difference is just noise.
			if _ticks == 1:
				_spider.global_position = _start
				(_spider as CharacterBody3D).velocity = Vector3.ZERO
				_overlap = 0.0
				return false
			var segs2: Array = (_solid.call("bone_segments")
					if _solid != null else _body.call("limb_segments"))
			_overlap = maxf(_overlap, _worst_self_overlap(segs2))
			if _ticks < 420:
				return false
			print("")
			print("[SOLID] worst limb overlap, run 1: %.4f m" % _avoid_on)
			print("[SOLID] worst limb overlap, run 2: %.4f m" % _overlap)
			print("")
			# Run-to-run spread, not a target. Anything claiming to
			# improve self-overlap has to beat THIS much noise.
			var spread: float = absf(_avoid_on - _overlap)
			_check(spread < 0.08,
					"the same walk twice gives a similar answer (%.4f m "
					% spread + "apart), so the measure means something")
			return _finish()
	return false


## How far a bone reaches inside the slab, in metres. Sampled along the
## bone, because a leg can be clean at both ends and buried at the knee
## — which is exactly what the first failed attempt looked like.
func _into_slab(a: Vector3, b: Vector3, r: float) -> float:
	var half := SLAB_SIZE * 0.5
	var worst := 0.0
	for i in 13:
		var p: Vector3 = a.lerp(b, float(i) / 12.0) - SLAB_AT
		# Depth inside the box on each axis; the smallest one is how far
		# in the point really is.
		var dx := half.x - absf(p.x)
		var dy := half.y - absf(p.y)
		var dz := half.z - absf(p.z)
		if dx > 0.0 and dy > 0.0 and dz > 0.0:
			worst = maxf(worst, minf(dx, minf(dy, dz)) + r)
	return worst


## Distance from a bone to the OUTSIDE of the slab (0 if inside).
func _to_slab(a: Vector3, b: Vector3) -> float:
	var half := SLAB_SIZE * 0.5
	var best := 999.0
	for i in 13:
		var p: Vector3 = a.lerp(b, float(i) / 12.0) - SLAB_AT
		var d := Vector3(
				maxf(absf(p.x) - half.x, 0.0),
				maxf(absf(p.y) - half.y, 0.0),
				maxf(absf(p.z) - half.z, 0.0))
		best = minf(best, d.length())
	return best


## The worst amount by which two bones of DIFFERENT legs pass through
## each other.
func _worst_self_overlap(segs: Array) -> float:
	var worst := 0.0
	for i in segs.size():
		for j in range(i + 1, segs.size()):
			if int(segs[i]["leg"]) == int(segs[j]["leg"]):
				continue      # same pair: they are meant to be close
			var gap := _seg_distance(segs[i]["a"], segs[i]["b"],
					segs[j]["a"], segs[j]["b"])
			var touch: float = float(segs[i]["r"]) + float(segs[j]["r"])
			if gap < touch:
				worst = maxf(worst, touch - gap)
	return worst


## Closest distance between two line segments, sampled. Sampling rather
## than solving: it only has to be good enough to compare two builds,
## and a wrong closed form would be worse than a coarse right one.
func _seg_distance(a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3) -> float:
	var best := INF
	for i in 7:
		var p: Vector3 = a1.lerp(a2, float(i) / 6.0)
		for j in 7:
			best = minf(best, p.distance_to(b1.lerp(b2, float(j) / 6.0)))
	return best


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
