extends SceneTree
## Smoke test for the Grabber's piston — STO-CHARACTER-067 (what it
## does) and STO-CHARACTER-068 (it is a real object).
##   godot --headless -s res://tests/smoke_piston.gd
##
## 067 delivered it as an instant hit in a radius: a normal attack
## wearing a piston's name. It is a shaft that actually shoots out now,
## connects with what it meets, retracts and has a cooldown.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _grabber: CharacterBody3D
var _enemy: CharacterBody3D
var _slow_len := 0.0


func _fire(charge: float) -> void:
	_grabber.set("_piston_cd", 0.0)
	_grabber.set("_piston_charge", charge)
	_grabber.call("fire_piston")


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				CharacterDB.selected_index = 0
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			var g: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
			g.name = "1"
			_main.get_node("Players").add_child(g)
			_grabber = g
			_grabber.global_position = Vector3(0.0, 1.0, 40.0)
			_enemy = _main.get_node("Enemies").get_child(0)
			_enemy.global_position = Vector3(200.0, 1.0, 200.0)   # out of the way
			_next("mode")
		"mode":
			if _ticks < 4:
				return false
			_check(bool(_grabber.call("toggle_piston")),
					"F locks the arms into a piston")
			_check(_grabber.call("piston_shaft") == null,
					"no shaft until it is fired")
			_next("slow")
		"slow":
			# A WEAK charge: the shaft still fires, just slowly.
			if _ticks == 1:
				_fire(0.05)
				return false
			if _ticks == 2:
				var shaft: Node3D = _grabber.call("piston_shaft")
				_check(shaft != null, "firing creates a REAL shaft")
				if shaft == null:
					return _finish()
				# It is solid: something you can stand on, not an area.
				_check(shaft is AnimatableBody3D,
						"the shaft is a solid body you could stand on")
				_check(shaft.get_node_or_null("CollisionShape3D") != null
								or shaft.get_child_count() >= 2,
						"and it has a collision shape")
				return false
			if _ticks < 12:
				return false
			var s1: Node3D = _grabber.call("piston_shaft")
			_slow_len = float(s1.call("shaft_length")) if s1 != null else 0.0
			_check(_slow_len > 0.0, "the slow shaft extended (%.2f m)" % _slow_len)
			_next("cooldown")
		"cooldown":
			# It cannot be spammed.
			if _ticks == 1:
				_grabber.set("_piston_charge", 1.6)
				var again := float(_grabber.call("fire_piston"))
				_check(is_equal_approx(again, 0.0),
						"a second shot is refused while on cooldown")
				return false
			if _ticks < 90:
				return false
			_check(_grabber.call("piston_shaft") == null,
					"the shaft retracts and goes away")
			_next("fast")
		"fast":
			# A FULL charge must fire FASTER than a weak one.
			if _ticks == 1:
				_fire(1.6)
				return false
			if _ticks < 12:
				return false
			var s2: Node3D = _grabber.call("piston_shaft")
			var fast_len := float(s2.call("shaft_length")) if s2 != null else 0.0
			_check(fast_len > _slow_len * 1.5,
					"a full charge fires far faster (%.2f m vs %.2f m in the same time)"
					% [fast_len, _slow_len])
			_next("aim")
		"aim":
			# ANY direction — straight up here.
			if _ticks < 90:
				return false
			if _ticks == 90:
				var cam := _grabber.get_node("Camera3D") as Camera3D
				cam.rotation.x = deg_to_rad(80.0)      # look up
				_fire(1.6)
				return false
			if _ticks < 100:
				return false
			var s3: Node3D = _grabber.call("piston_shaft")
			if s3 == null:
				_check(false, "a shaft exists when aiming up")
				return _finish()
			# +Z, not -Z: the shaft is built along its local +Z and
			# oriented with Quaternion(+Z, dir), so +Z IS the direction
			# it was fired.
			var up_dir := s3.global_transform.basis.z
			_check(up_dir.y > 0.5,
					"it fires where you AIM, including straight up (y %.2f)"
					% up_dir.y)
			_next("enemy")
		"enemy":
			# An enemy in its path is launched AND ragdolled.
			if _ticks < 90:
				return false
			if _ticks == 90:
				var cam2 := _grabber.get_node("Camera3D") as Camera3D
				cam2.rotation.x = 0.0
				_enemy.global_position = _grabber.global_position \
						+ Vector3(0.0, 0.1, -2.5)
				_fire(1.6)
				return false
			if _ticks < 130:
				return false
			var rag := _enemy.get_parent().get_node_or_null(
					String(_enemy.name) + "Ragdoll")
			_check(rag != null, "an enemy the shaft reaches IS ragdolled")
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
