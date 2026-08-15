extends SceneTree
## Smoke test for STO-ENEMIES-048 — the arms reach out for you.
##   godot --headless -s res://tests/smoke_arms_reach.gd
##
## The measurement is the ANGLE between where an arm is actually
## pointing and the direction to the target, read off the arm's own tip
## in world space. That is deliberate: a check like "aim_at was called"
## or "is_aiming() is true" would prove the code ran while the arms sat
## exactly where they always sat, which is the mistake the failed limb
## collision already made in this project.
##
## So the test aims at a target OFF TO ONE SIDE and behind, which the
## rest pose points nowhere near. Aiming straight ahead would pass with
## the arms welded solid, because they already point forwards.

const PincerScript := preload("res://scripts/pincers.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _arms: Node3D
var _idle_err := 0.0
var _target := Vector3(4.0, 1.2, 3.5)   # off to the side AND behind


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				var holder := Node3D.new()
				root.add_child(holder)
				_arms = PincerScript.new()
				_arms.set("variation_seed", 12345)
				holder.add_child(_arms)
				var mat := StandardMaterial3D.new()
				_arms.call("build", Vector3(0.3, 0.17, 0.4), 2.0, mat)
				return false
			_check(int(_arms.call("arm_count")) == 2, "two arms were built")
			_check(not bool(_arms.call("is_aiming")),
					"they are not reaching for anything to begin with")
			_next("idle")

		"idle":
			# Let the idle weave run so the reading is a real resting
			# pose rather than the first frame of one.
			if _ticks < 30:
				return false
			_idle_err = _worst_error()
			print("[REACH] idling, worst arm is %.1f deg off the target"
					% rad_to_deg(_idle_err))
			_check(_idle_err > deg_to_rad(45.0),
					"idling, the arms point nowhere near the target "
					+ "(%.1f deg off)" % rad_to_deg(_idle_err))
			_next("reach")

		"reach":
			_arms.call("aim_at", _target)
			_arms.call("set_reach", 1.0)
			if _ticks < 60:
				return false
			var err := _worst_error()
			var out := float(_arms.call("reach_out"))
			print("[REACH] reaching, worst arm is %.1f deg off (reach_out %.2f)"
					% [rad_to_deg(err), out])
			_check(err < _idle_err * 0.5,
					"reaching, both arms swing round toward it: %.1f deg -> "
					% rad_to_deg(_idle_err) + "%.1f deg" % rad_to_deg(err))
			_check(err < deg_to_rad(30.0),
					"and they end up genuinely pointed at it (%.1f deg)"
					% rad_to_deg(err))
			_check(out > 0.9, "the arms are fully extended (%.2f)" % out)
			_next("follow")

		"follow":
			# A moving target. There is no recorded animation, so this
			# should work for free — and if it ever stops working, the
			# reach has quietly become a canned pose.
			_target = Vector3(-4.5, 0.6, 2.0)
			_arms.call("aim_at", _target)
			if _ticks < 60:
				return false
			var err := _worst_error()
			print("[REACH] target moved to the other side, now %.1f deg off"
					% rad_to_deg(err))
			_check(err < deg_to_rad(30.0),
					"they follow the target when it moves (%.1f deg)"
					% rad_to_deg(err))
			_next("release")

		"release":
			_arms.call("clear_aim")
			_arms.call("set_reach", 0.0)
			if _ticks < 60:
				return false
			var err := _worst_error()
			print("[REACH] released, back to %.1f deg off" % rad_to_deg(err))
			_check(err > deg_to_rad(45.0),
					"and they let go and go back to idling (%.1f deg)"
					% rad_to_deg(err))
			_check(float(_arms.call("reach_out")) < 0.1,
					"the arms are drawn back in")
			return _finish()
	return false


## The worse of the two arms' aim errors. Worse, not average: one arm
## finding the target while the other stares at the floor is not
## reaching for you.
func _worst_error() -> float:
	var worst := 0.0
	for i in 2:
		worst = maxf(worst, float(_arms.call("aim_error", i, _target)))
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
