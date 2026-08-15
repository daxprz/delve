extends SceneTree
## Smoke test for STO-ENEMIES-052 — the arms feel around.
##   godot --headless -s res://tests/smoke_spider_feel.gd
##
## Two checks carry this file, and both are comparisons:
##
## 1. It feels the NEAR thing and NOT the far one. A test with one
##    object would pass for a sense that simply returns everything in
##    the level, which is the omniscience this whole direction exists
##    to get rid of.
##
## 2. Searching sweeps a BIGGER volume than idling. "is_searching() is
##    true" proves a flag flipped; it says nothing about whether the
##    arms moved differently, and the operator asked for this to look
##    creepier, not to be true.

const PincerScript := preload("res://scripts/pincers.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _holder: Node3D
var _arms: Node3D
var _near: StaticBody3D
var _far: StaticBody3D
var _idle_span := 0.0
var _search_span := 0.0
var _lo := Vector3.ONE * 999.0
var _hi := Vector3.ONE * -999.0
var _reach_lo := 9.0
var _reach_hi := -9.0
var _swept_mid := Vector3.ZERO


func _block(nm: String, at: Vector3, size := 3.0) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = nm
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3.ONE * size
	cs.shape = bx
	b.add_child(cs)
	_holder.get_parent().add_child(b)
	b.global_position = at
	return b


func _span() -> Vector3:
	return _hi - _lo


func _sample() -> void:
	for i in 2:
		var t: Vector3 = _arms.call("tip_position", i)
		_lo = Vector3(minf(_lo.x, t.x), minf(_lo.y, t.y), minf(_lo.z, t.z))
		_hi = Vector3(maxf(_hi.x, t.x), maxf(_hi.y, t.y), maxf(_hi.z, t.z))


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				var world := Node3D.new()
				root.add_child(world)
				_holder = Node3D.new()
				world.add_child(_holder)
				_arms = PincerScript.new()
				_arms.set("variation_seed", 4242)
				_holder.add_child(_arms)
				var mat := StandardMaterial3D.new()
				_arms.call("build", Vector3(0.37, 0.21, 0.49), 3.12, mat)
				return false
			_check(not bool(_arms.call("is_searching")),
					"the arms are not searching to begin with")
			_check((_arms.call("felt") as Array).is_empty(),
					"and have felt nothing")
			_next("idle")

		"idle":
			# How much space the tips cover while merely idling.
			_sample()
			if _ticks < 200:
				return false
			_idle_span = _span().length()
			print("[FEEL] idling, the tips cover %.2f m of space"
					% _idle_span)
			_lo = Vector3.ONE * 999.0
			_hi = Vector3.ONE * -999.0
			_next("search")

		"search":
			if _ticks == 1:
				_arms.call("set_searching", true)
				return false
			_sample()
			var out: float = float(_arms.call("reach_out"))
			_reach_lo = minf(_reach_lo, out)
			_reach_hi = maxf(_reach_hi, out)
			if _ticks < 400:
				return false
			_swept_mid = (_lo + _hi) * 0.5
			_search_span = _span().length()
			print("[FEEL] searching, the tips cover %.2f m" % _search_span)
			print("[FEEL] and the reach breathes between %.2f and %.2f"
					% [_reach_lo, _reach_hi])
			_check(bool(_arms.call("is_searching")), "they are searching")
			# The check that matters: searching must LOOK different.
			_check(_search_span > _idle_span * 1.4,
					"searching sweeps a far bigger space than idling "
					+ "(%.2f m vs %.2f m) — it looks different, not just "
					% [_search_span, _idle_span] + "flagged different")
			_check(_reach_hi - _reach_lo > 0.3,
					"and the arms reach OUT and draw back (%.2f) rather "
					% (_reach_hi - _reach_lo) + "than holding one pose")
			_next("touch")

		"touch":
			# Something within arm's reach, and something far away.
			if _ticks == 1:
				var r: float = float(_arms.call("reach"))
				# At the height the ARMS actually are, not on the floor.
				# The first version put both blocks at the holder's
				# origin, three metres BELOW the shoulders — so the tips
				# swept a space with nothing in it and the sense reported
				# an empty world, correctly.
				# Placed in the MIDDLE of the volume the tips were just
				# measured sweeping through. Guessing where the arms go
				# failed twice — once three metres too low, once by
				# reasoning about reach — and a sense that finds nothing
				# because the test put the object somewhere else is
				# indistinguishable from a sense that does not work.
				print("[FEEL] arm reach %.2f m; tips swept a box centred "
						% r + "on %.1f, %.1f, %.1f"
						% [_swept_mid.x, _swept_mid.y, _swept_mid.z])
				# A wall-sized obstacle, not a target to hit. The tips
				# roam six metres across, so a 1.2 m box is a needle they
				# only thread by luck — and "it missed" is
				# indistinguishable from "it cannot feel".
				_near = _block("Near", _swept_mid, 4.0)
				_far = _block("Far", _swept_mid
						+ Vector3(0.0, 0.0, -r * 6.0), 4.0)
				return false
			_arms.call("feel", _holder.get_world_3d(), RID())
			if _ticks < 600:
				return false
			var felt_near: bool = bool(_arms.call("has_felt", _near))
			var felt_far: bool = bool(_arms.call("has_felt", _far))
			var names: Array = []
			for f in (_arms.call("felt") as Array):
				if not names.has(f["name"]):
					names.append(f["name"])
			print("[FEEL] touched: %s" % str(names))
			_check(felt_near,
					"it FEELS the thing within arm's reach")
			_check(not felt_far,
					"and NOT the one far away — this is a short sense, "
					+ "not the radar")
			_next("stop")

		"stop":
			_arms.call("set_searching", false)
			if _ticks < 5:
				return false
			_check(not bool(_arms.call("is_searching")),
					"it stops searching when told")
			_check((_arms.call("felt") as Array).is_empty(),
					"and forgets what it felt, so stale touches cannot "
					+ "be acted on later")
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
