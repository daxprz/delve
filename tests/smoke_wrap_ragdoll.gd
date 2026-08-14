extends SceneTree
## Smoke test for STO-CHARACTER-063 — the fingers wrap a grabbed
## ragdoll and keep hold while it is dragged along the ground.
##   godot --headless -s res://tests/smoke_wrap_ragdoll.gd
##
## A ragdoll is the hardest case: a crate is one rigid box that stays
## where it is put, while a limp enemy is eleven jointed parts that
## tumble, swing and catch on the floor as you haul them about. A grip
## that survives that survives anything.

const CharacterDB := preload("res://scripts/characters.gd")
const SETTLE := 90
const NAMES: Array = ["Pointer", "Middle", "Ring", "Pinky", "Thumb"]

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _arms
var _enemy: CharacterBody3D
var _held_part: RigidBody3D
var _before: Dictionary = {}


func _curls() -> Dictionary:
	var out: Dictionary = {}
	for nm in NAMES:
		out[nm] = float(_arms.call("finger_curl", 0, nm))
	return out


func _spread(c: Dictionary) -> float:
	var lo := 9.0
	var hi := -9.0
	for nm in NAMES:
		lo = minf(lo, float(c[nm]))
		hi = maxf(hi, float(c[nm]))
	return hi - lo


func _fmt(c: Dictionary) -> String:
	var parts: Array = []
	for nm in NAMES:
		parts.append("%s %.2f" % [String(nm).substr(0, 2), float(c[nm])])
	return ", ".join(parts)


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0        # Grabber
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_player = p
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_arms = _player.get_node_or_null("MechanicalArms")
			var enemies: Node3D = _main.get_node("Enemies")
			if _arms == null or enemies.get_child_count() == 0:
				_check(false, "there is a Grabber and an enemy")
				return _finish()
			_enemy = enemies.get_child(0)
			_enemy.global_position = Vector3(1.2, 1.0, 40.0)
			_next("ragdoll")
		"ragdoll":
			if _ticks < 4:
				return false
			if _ticks == 4:
				# Grabbing an enemy makes it go limp — the real path.
				var rag = _enemy.call("ragdoll_now")
				_check(rag != null, "grabbing an enemy ragdolls it")
				if rag == null:
					return _finish()
				_held_part = rag.call("part", "Torso")
				if _held_part == null:
					_held_part = rag.call("part", "Pelvis")
				_check(_held_part != null, "there is a body part to hold")
				if _held_part == null:
					return _finish()
				_arms.call("grab_body", 0, _held_part, _held_part.global_position)
				return false
			if _ticks < SETTLE:
				return false
			var c := _curls()
			for nm in NAMES:
				_check(float(c[nm]) > 0.0,
						"%s closed on the body (%.2f)" % [nm.to_lower(), float(c[nm])])
			_check(_spread(c) > 0.02,
					"fingers close by DIFFERENT amounts on it (spread %.3f: %s)"
					% [_spread(c), _fmt(c)])
			_before = c
			_next("drag")
		"drag":
			# THE hard part: haul the body across the ground and the
			# grip must re-fit rather than freeze in its first pose.
			if _ticks < 120:
				_player.global_position -= Vector3(0.0, 0.0, 0.03)
				return false
			_check(is_instance_valid(_held_part),
					"the body survived being dragged")
			if not is_instance_valid(_held_part):
				return _finish()
			var dragged := _curls()
			var changed := 0
			for nm in NAMES:
				if absf(float(dragged[nm]) - float(_before[nm])) > 0.02:
					changed += 1
			_check(changed > 0,
					"the grip re-fits while dragging (%d of 5 fingers changed)"
					% changed)
			for nm2 in NAMES:
				_check(float(dragged[nm2]) > 0.0,
						"%s still holds on after the drag (%.2f)"
						% [nm2.to_lower(), float(dragged[nm2])])
			# Still a hand shape: nothing folded through the body.
			_check(_spread(dragged) >= 0.0 and _spread(dragged) < 1.01,
					"the hand is still a hand (%s)" % _fmt(dragged))
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
			_check(all_rest, "letting the body go opens the hand (%s)" % _fmt(open))
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
