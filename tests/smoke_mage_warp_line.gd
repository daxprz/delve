extends SceneTree
## Smoke tests for STO-CHARACTER-082 (the slow warp) and
## STO-CHARACTER-080 (enemies only count while on the line).
##   godot --headless -s res://tests/smoke_mage_warp_line.gd
##
## For the warp, the story is explicit about what would be too easy:
##
##   > a test can sample it halfway and find it HALF WARPED, not "round"
##   > or "flat" ... A test that only checks the start and the end would
##   > pass for an instant snap.
##
## So it is sampled at several points and has to be different at each,
## and it has to still be SOLID halfway — otherwise the slow warp is
## just decoration over an instant ability.
##
## For the line, the operator's rule is that an enemy is in his world
## only while its hitbox is on the plane, and that it can go IN AND OUT.
## So the test walks one across and demands out -> in -> out. A test
## that only found it while it stood on the line would pass for a rule
## that never lets anything leave.

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _mage: Node
var _mob: CharacterBody3D
var _samples: Array = []
var _mid_warp := -1.0
var _mid_solid := false
var _seen_off_before := false
var _seen_on := false
var _seen_off_after := false
var _normal := Vector3.ZERO


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				var db = load(CHARS)
				for i in int(db.count()):
					if String(db.get_def(i)["id"]) == "mage":
						db.selected_index = i
				var p: CharacterBody3D = (load(PLAYER_SCENE)
						as PackedScene).instantiate()
				p.name = "1"
				_main.get_node("Players").add_child(p)
				_mage = p
				return false
			if _ticks < 45:
				return false
			# The real spider out of the way — it hunts, and being
			# grabbed suspends the plane.
			for e in _main.get_node("Enemies").get_children():
				(e as Node3D).global_position = Vector3(0.0, 0.0, 700.0)
			for d in get_nodes_in_group("dummies"):
				(d as Node3D).global_position = Vector3(0.0, 0.0, 720.0)
			(_mage as Node3D).rotation.y = 0.0
			_check(_mage.has_method("warp"), "the warp can be measured")
			_check(float(_mage.call("warp")) < 0.01, "and starts at zero")
			_next("warping")

		"warping":
			if _ticks == 1:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			# Sampled all the way through, not just at the ends.
			if _ticks % 12 == 0 and _ticks <= 72:
				_samples.append(float(_mage.call("warp")))
			# Halfway: he must be genuinely mid-warp AND still solid.
			if _ticks == 36:
				_mid_warp = float(_mage.call("warp"))
				_mid_solid = not _hitbox_is_thin()
				return false
			if _ticks < 130:
				return false
			print("[WARP] samples through the warp: %s"
					% str(_samples.map(func(v): return "%.2f" % v)))
			_check(_samples.size() >= 4, "sampled enough times")
			var rising := true
			for i in range(1, _samples.size()):
				if float(_samples[i]) <= float(_samples[i - 1]):
					rising = false
			_check(rising,
					"it warps CONTINUOUSLY — every sample further on than "
					+ "the last, so it is a warp and not a snap")
			print("[WARP] halfway it was %.2f warped, hitbox still solid: %s"
					% [_mid_warp, str(_mid_solid)])
			_check(_mid_warp > 0.1 and _mid_warp < 0.9,
					"caught halfway it is HALF WARPED (%.2f)" % _mid_warp)
			_check(_mid_solid,
					"and still SOLID halfway — being partly flat does not "
					+ "yet let him through anything")
			_check(float(_mage.call("warp")) > 0.99, "it finishes")
			var cs0 := _mage.get_node_or_null("CollisionShape3D") as CollisionShape3D
			print("[WARP] warp=%.4f shape=%s" % [float(_mage.call("warp")),
					(cs0.shape.get_class() if cs0 and cs0.shape else "none")])
			_check(_hitbox_is_thin(),
					"and only THEN does the hitbox go thin")
			_next("line_setup")

		"line_setup":
			_normal = _mage.call("plane_normal")
			# A mob that will walk across his plane, starting well off it.
			_mob = CharacterBody3D.new()
			_mob.name = "Wanderer"
			_mob.add_to_group("enemies")
			var cs := CollisionShape3D.new()
			var cap := CapsuleShape3D.new()
			cap.radius = 0.4
			cap.height = 1.6
			cs.shape = cap
			_mob.add_child(cs)
			_main.add_child(_mob)
			_mob.global_position = (_mage as Node3D).global_position \
					+ _normal * 8.0
			_next("crossing")

		"crossing":
			# Walk it straight across the plane: far side -> on it -> far
			# side again.
			var t: float = float(_ticks) * 0.12
			_mob.global_position = (_mage as Node3D).global_position \
					+ _normal * (8.0 - t)
			var on: bool = bool(_mage.call("is_on_my_line", _mob))
			var off_by: float = float(_mage.call("distance_off_plane",
					_mob.global_position))
			if not _seen_on:
				if off_by > 3.0 and not on:
					_seen_off_before = true
			elif not on and off_by > 3.0:
				_seen_off_after = true
			if on:
				_seen_on = true
			if _ticks < 140:
				return false
			print("[LINE] walking across: off first=%s, ON=%s, off after=%s"
					% [str(_seen_off_before), str(_seen_on),
					str(_seen_off_after)])
			_check(_seen_off_before,
					"well off his plane, an enemy is NOT in his world")
			_check(_seen_on,
					"stepping onto the line, it IS")
			_check(_seen_off_after,
					"and stepping off again it stops being — in and OUT, "
					+ "by where it is standing")
			_next("solid_again")

		"solid_again":
			# Not flat: nothing is on his line, because he has no line.
			if _ticks == 1:
				_mob.global_position = (_mage as Node3D).global_position \
						+ Vector3.UP * 0.1
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			if _ticks < 130:
				return false
			_check(not bool(_mage.call("is_flat")), "he comes back solid")
			_check(not bool(_mage.call("is_on_my_line", _mob)),
					"and with no plane, nothing is 'on his line' — even a "
					+ "mob standing on top of him")
			_check(int((_mage.call("things_on_my_line") as Array).size())
					== 0, "the list is empty when he is not flat")
			return _finish()
	return false


## Read off the real collider rather than a flag: the point of the
## halfway check is what the WORLD thinks he is, not what he says.
func _hitbox_is_thin() -> bool:
	var cs := _mage.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		return false
	return cs.shape is BoxShape3D


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
