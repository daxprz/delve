extends SceneTree
## Smoke test for STO-ENEMIES-051 — held by one leg, and limp.
##   godot --headless -s res://tests/smoke_held_by_leg.gd
##
## "A ragdoll exists" is not the check. A ragdoll standing neatly
## upright would satisfy that and would look nothing like what was
## asked for. The load-bearing measurement is that **the head ends up
## below the held leg** — that is what "hanging off one leg" means, and
## it is false for any body that is merely limp on the spot.
##
## Also guards the rule this story deliberately breaks: nothing else in
## delve may ragdoll a player.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _p: Node
var _grip := Vector3(0.0, 1.6, 0.0)
var _head_sum := 0.0
var _head_n := 0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				var floor_body := StaticBody3D.new()
				var cs := CollisionShape3D.new()
				var bx := BoxShape3D.new()
				bx.size = Vector3(60.0, 1.0, 60.0)
				cs.shape = bx
				floor_body.add_child(cs)
				root.add_child(floor_body)
				floor_body.global_position = Vector3(0.0, -0.5, 0.0)
				_p = (load(PLAYER_SCENE) as PackedScene).instantiate()
				_p.name = "Victim"
				root.add_child(_p)
				return false
			if _ticks < 5:
				return false
			_check(_p.has_method("go_limp"), "a player can be made limp")
			_check(not bool(_p.call("is_limp")),
					"but is NOT limp to begin with — this is the exception, "
					+ "not the rule")
			_next("grabbed")

		"grabbed":
			if _ticks == 1:
				var captor := Node3D.new()
				captor.name = "PretendSpider"
				root.add_child(captor)
				_p.call("grabbed_by", captor)
				return false
			_check(bool(_p.call("is_limp")),
					"caught, the body goes limp")
			var leg := String(_p.call("held_leg"))
			print("[LIMP] held by %s" % leg)
			_check(leg == "ShinL" or leg == "ShinR",
					"and it has hold of ONE LEG (%s)" % leg)
			_next("dangle")

		"dangle":
			# Held up by the leg, everything else must fall.
			_p.call("dragged_to", _grip)
			if _ticks < 90:
				return false
			var leg_at: Vector3 = _p.call("held_leg_position")
			var head_at: Vector3 = _p.call("limp_head_position")
			var hang := leg_at.y - head_at.y
			print("[LIMP] leg at y=%.2f, head at y=%.2f -> head hangs %.2f m "
					% [leg_at.y, head_at.y, hang] + "below the grip")
			_check(leg_at.distance_to(_grip) < 0.5,
					"the held leg stays where the spider puts it (%.2f m off)"
					% leg_at.distance_to(_grip))
			_check(hang > 0.4,
					"and the rest of the body hangs BELOW it — head %.2f m "
					% hang + "under the held leg")
			_next("dragged_low")

		"dragged_low":
			# STO-ENEMIES-034's rule still holds: along the ground.
			#
			# Measured as an AVERAGE over the whole drag, and RELATIVE to
			# where the spider is holding him — not as one instant
			# against an absolute height. A ragdoll being hauled by one
			# leg flails, and a single sample caught the head anywhere
			# from 3 m below the grip to 5 m above it. Sampling one
			# instant of a chaotic thing is not a measurement.
			_grip = Vector3(0.0, 0.35, 0.0)
			_p.call("dragged_to", _grip)
			var h: Vector3 = _p.call("limp_head_position")
			_head_sum += h.y
			_head_n += 1
			if _ticks < 90:
				return false
			var avg := _head_sum / float(_head_n)
			print("[LIMP] dragged low: head averaged y=%.2f over %d samples "
					% [avg, _head_n] + "(grip at y=%.2f)" % _grip.y)
			_check(avg < _grip.y + 0.8,
					"dragged at ground level, the body stays at or below "
					+ "the grip (head averaged %.2f, grip %.2f)"
					% [avg, _grip.y])
			_next("stand")

		"stand":
			if _ticks == 1:
				_p.call("released")
				return false
			if _ticks < 20:
				return false
			_check(not bool(_p.call("is_limp")),
					"freed, the player gets their body back")
			_check(String(_p.call("held_leg")) == "",
					"and nothing has hold of them")
			# No ragdoll left lying in the world.
			var leftovers := 0
			for c in root.get_children():
				if String(c.name).ends_with("Limp"):
					leftovers += 1
			print("[LIMP] ragdolls left in the world: %d" % leftovers)
			_check(leftovers == 0,
					"and no limp body is left behind (%d found)" % leftovers)
			_check(_p.get_node_or_null("Body") != null
					and (_p.get_node("Body") as Node3D).visible,
					"their real body is visible again")
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
