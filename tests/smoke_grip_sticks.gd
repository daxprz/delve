extends SceneTree
## Smoke test for STO-CHARACTER-062 — each finger finds the surface for
## itself, and the grip keeps re-fitting as things move.
##   godot --headless -s res://tests/smoke_grip_sticks.gd
##
## STO-CHARACTER-059 closed all five fingers by the same amount, from
## the object's overall size. That is fine standing still and wrong the
## moment anything moves. This checks the two things that separate a
## hand that IS holding something from one posed once and left:
##
##   * different fingers reach different distances, so they close by
##     different amounts
##   * the curls change when the object moves in the grip

const CharacterDB := preload("res://scripts/characters.gd")
const SETTLE := 90
const NAMES: Array = ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _arms
var _bar: RigidBody3D
var _before: Dictionary = {}


func _curls() -> Dictionary:
	var out: Dictionary = {}
	for nm in NAMES:
		out[nm] = float(_arms.call("finger_curl", 0, nm))
	return out


func _spread_of(c: Dictionary) -> float:
	var lo := 9.0
	var hi := -9.0
	for nm in NAMES:
		lo = minf(lo, float(c[nm]))
		hi = maxf(hi, float(c[nm]))
	return hi - lo


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_player = p
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_arms = _player.get_node_or_null("MechanicalArms")
			if _arms == null:
				_check(false, "the Grabber has arms")
				return _finish()
			# A long BAR, deliberately: it reaches past some fingers and
			# not others, so a per-finger grip has something to differ
			# about. A cube would let one shared curl look correct.
			_bar = RigidBody3D.new()
			_bar.name = "Bar"
			_bar.gravity_scale = 0.0
			var cs := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.9, 0.16, 0.16)
			cs.shape = box
			_bar.add_child(cs)
			_main.add_child(_bar)
			_bar.global_position = Vector3(0.8, 1.0, 40.0)
			_next("grab")
		"grab":
			if _ticks == 1:
				_arms.call("grab_body", 0, _bar, _bar.global_position)
				return false
			if _ticks < SETTLE:
				return false
			var c := _curls()
			# EVERY finger has its own value, not one shared number.
			_check(_spread_of(c) > 0.02,
					"fingers close by DIFFERENT amounts (spread %.3f: %s)"
					% [_spread_of(c), _fmt(c)])
			for nm in NAMES:
				_check(float(c[nm]) > 0.0,
						"%s closed on it (%.2f)" % [nm.to_lower(), float(c[nm])])
			_before = c
			_next("move")
		"move":
			# THE POINT: shift the object in the grip and the hand
			# re-fits, rather than dragging the pose it started with.
			if _ticks == 1:
				_bar.global_position += Vector3(0.0, -0.22, 0.0)
				return false
			if _ticks < SETTLE:
				return false
			var moved := _curls()
			var changed := 0
			for nm in NAMES:
				if absf(float(moved[nm]) - float(_before[nm])) > 0.02:
					changed += 1
			_check(changed > 0,
					"moving the object re-fits the grip (%d of 5 fingers changed)"
					% changed)
			_next("turn")
		"turn":
			# Turning the player moves the hand relative to the object;
			# the grip must follow that too.
			if _ticks == 1:
				_before = _curls()
				_player.rotation.y += deg_to_rad(35.0)
				return false
			if _ticks < SETTLE:
				return false
			var turned := _curls()
			var moved2 := 0
			for nm in NAMES:
				if absf(float(turned[nm]) - float(_before[nm])) > 0.02:
					moved2 += 1
			_check(moved2 > 0,
					"turning re-fits the grip too (%d of 5 changed)" % moved2)
			_next("release")
		"release":
			if _ticks == 1:
				_arms.call("release", 0)
				return false
			if _ticks < SETTLE:
				return false
			var open := _curls()
			var all_rest := true
			for nm in NAMES:
				if float(open[nm]) > 0.25:
					all_rest = false
			_check(all_rest, "letting go opens every finger (%s)" % _fmt(open))
			return _finish()
	return false


func _fmt(c: Dictionary) -> String:
	var parts: Array = []
	for nm in NAMES:
		parts.append("%s %.2f" % [String(nm).substr(0, 2), float(c[nm])])
	return ", ".join(parts)


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
