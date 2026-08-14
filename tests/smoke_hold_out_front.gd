extends SceneTree
## Smoke test for STO-CHARACTER-054 — a held thing is held OUT IN
## FRONT, not hugged against the player.
##   godot --headless -s res://tests/smoke_hold_out_front.gd
##
## The carry point used to be player origin + 0.3 m up + 1.6 m
## forward: knee height, tucked in. It read as being pulled to you,
## and it sat in the way of the aim you were lining up.
##
## Measures where the object actually ends up rather than reading the
## constants back — the constants looking right is what was true
## while it was wrong.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _player: CharacterBody3D
var _box: RigidBody3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0     # Grabber
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			# Spawn directly rather than hosting (STO-TOOLS-009), so
			# this runs while the operator has the game open.
			var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			p.name = "1"
			_main.get_node("Players").add_child(p)
			_player = p
			_box = _main.get_node_or_null("Playground/MovableBox") as RigidBody3D
			_check(_box != null, "there is a box to pick up")
			if _box == null:
				return _finish()
			_next("grab")
		"grab":
			if _ticks < 3:
				return false
			# Put the box within reach and pick it up.
			_player.global_position = Vector3(0.0, 1.0, 40.0)
			_box.global_position = _player.global_position + Vector3(0.0, 0.5, -1.5)
			_player.call("do_throw")           # first press = pick up
			_check(_player.call("held_object") == _box,
					"the box is picked up")
			if _player.call("held_object") != _box:
				return _finish()
			_next("held")
		"held":
			if _ticks < 6:
				return false
			var cam := _player.get_node("Camera3D") as Camera3D
			var eye := cam.global_position
			var to_box: Vector3 = _box.global_position - eye
			var forward := -cam.global_transform.basis.z

			# OUT IN FRONT: clearly away from the body, not hugged.
			var dist := to_box.length()
			_check(dist > 1.8,
					"it is held out away from the player (%.2f m from the eye)"
					% dist)
			# ...and in front, not off to the side or behind.
			_check(to_box.normalized().dot(forward) > 0.9,
					"it is held in FRONT of where you look (dot %.2f)"
					% to_box.normalized().dot(forward))
			# EYE LEVEL, not knee level. The old carry point sat at
			# player origin + 0.3, which is about 1.3 m BELOW the eye.
			var drop := eye.y - _box.global_position.y
			_check(drop < 0.6,
					"it is held near eye level, not by the knees (%.2f m below eye)"
					% drop)
			_next("look_up")
		"look_up":
			# It must follow the look direction up and down, or you
			# cannot line a throw up at anything above or below you.
			if _ticks == 1:
				var cam := _player.get_node("Camera3D") as Camera3D
				cam.rotation.x = deg_to_rad(35.0)   # look up
				return false
			if _ticks < 6:
				return false
			var cam2 := _player.get_node("Camera3D") as Camera3D
			var eye2 := cam2.global_position
			var fwd2 := -cam2.global_transform.basis.z
			var to_box2: Vector3 = _box.global_position - eye2
			_check(to_box2.normalized().dot(fwd2) > 0.9,
					"it follows the aim upward (dot %.2f)"
					% to_box2.normalized().dot(fwd2))
			_check(_box.global_position.y > eye2.y,
					"looking up actually raises it (box %.2f vs eye %.2f)"
					% [_box.global_position.y, eye2.y])
			_next("throw")
		"throw":
			if _ticks < 2:
				var cam3 := _player.get_node("Camera3D") as Camera3D
				cam3.rotation.x = 0.0
				return false
			if _ticks == 2:
				_thrown_from = _box.global_position
				_player.call("do_throw")       # second press = hurl it
				_check(_player.call("held_object") == null,
						"throwing lets go of it")
				return false
			if _ticks < 30:
				return false
			var moved := _box.global_position.distance_to(_thrown_from)
			_check(moved > 1.0,
					"the throw actually sends it somewhere (%.2f m)" % moved)
			return _finish()
	return false


var _thrown_from := Vector3.ZERO


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
