extends SceneTree
## Smoke test for STO-CHARACTER-055 — RMB picks a loose object up and
## holds it OUT IN FRONT.
##   godot --headless -s res://tests/smoke_rmb_pickup.gd
##
## Supersedes the behaviour STO-CHARACTER-053 asked for (the crate
## staying exactly where it was). The one thing constant across every
## version: it must never be dragged INTO the player.
##
## Measures where the crate actually ends up rather than reading the
## constants — the constants looking right is what was true while this
## was wrong.

const CharacterDB := preload("res://scripts/characters.gd")
const SETTLE := 40

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _arms
var _box: RigidBody3D
var _start_dist := 0.0


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0     # Grabber
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			# Spawn directly rather than hosting (STO-TOOLS-009).
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_player = p
			_box = _main.get_node_or_null("Playground/MovableBox") as RigidBody3D
			_arms = _player.get_node_or_null("MechanicalArms")
			_check(_box != null, "there is a box")
			_check(_arms != null, "the Grabber has arms")
			if _box == null or _arms == null:
				return _finish()
			_next("grab")
		"grab":
			if _ticks < 3:
				return false
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_box.global_position = _player.global_position + Vector3(0.0, 0.5, -2.0)
			# Arm 1 is the RIGHT arm (RMB).
			_arms.grab_body(1, _box, _box.global_position)
			_check(_arms.is_grabbed(1), "RMB grabs the box")
			if not _arms.is_grabbed(1):
				return _finish()
			_start_dist = _player.global_position.distance_to(_box.global_position)
			_next("held")
		"held":
			if _ticks < SETTLE:
				return false
			var cam := _player.get_node("Camera3D") as Camera3D
			var eye := cam.global_position
			var fwd := -cam.global_transform.basis.z
			var to_box: Vector3 = _box.global_position - eye
			var dist := to_box.length()

			# HELD OUT, not dragged in.
			_check(dist > 1.8,
					"it is held out away from the player (%.2f m from the eye)"
					% dist)
			_check(to_box.normalized().dot(fwd) > 0.85,
					"it is held in FRONT of where you look (dot %.2f)"
					% to_box.normalized().dot(fwd))
			# EYE LEVEL, not hip or knee height.
			var drop := eye.y - _box.global_position.y
			_check(absf(drop) < 0.8,
					"it is held near eye level (%.2f m from the eye line)" % drop)
			# THE ONE CONSTANT across every version of this behaviour.
			var player_dist := _player.global_position.distance_to(_box.global_position)
			_check(player_dist > 1.0,
					"it was NOT dragged into the player (%.2f m away)"
					% player_dist)
			_next("look_up")
		"look_up":
			if _ticks == 1:
				var cam2 := _player.get_node("Camera3D") as Camera3D
				cam2.rotation.x = deg_to_rad(35.0)
				return false
			if _ticks < SETTLE:
				return false
			var cam3 := _player.get_node("Camera3D") as Camera3D
			_check(_box.global_position.y > cam3.global_position.y,
					"looking up raises it (box %.2f vs eye %.2f)"
					% [_box.global_position.y, cam3.global_position.y])
			_next("release")
		"release":
			if _ticks == 1:
				var cam4 := _player.get_node("Camera3D") as Camera3D
				cam4.rotation.x = 0.0
				_arms.release(1)
				_check(not _arms.is_grabbed(1), "releasing RMB lets go")
				return false
			if _ticks < 40:
				return false
			# Once let go it is an ordinary object again: it falls.
			_check(_box.global_position.y < 2.5,
					"a released box drops instead of hovering (y %.2f)"
					% _box.global_position.y)
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
