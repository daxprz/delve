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
var _piston_arms
var _apart_grab := 0.0
var _up_from := Vector3.ZERO


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
			_piston_arms = _grabber.get_node_or_null("MechanicalArms")
			_apart_grab = float(_piston_arms.call("hand_point", 0)
					.distance_to(_piston_arms.call("hand_point", 1)))
			_check(_apart_grab > 0.3,
					"in grab mode the two hands are apart (%.3f m)"
					% _apart_grab)
			_next("join")
		"join":
			# THE HANDS COMBINE (STO-CHARACTER-070): both arms are drawn
			# to one point so they lock into a single shaft, instead of
			# the piston appearing out of thin air beside two dangling
			# arms.
			if _ticks < 45:
				return false
			var apart := float(_piston_arms.call("hand_point", 0)
					.distance_to(_piston_arms.call("hand_point", 1)))
			# A flat plate on the front, and ARMS HELD OUT — machinery
			# under power, not limbs hanging (STO-CHARACTER-073).
			_check(bool(_piston_arms.call("plate_visible")),
					"the piston carries a flat plate on its front")
			var sh: Vector3 = _piston_arms.call("shoulder_point", 0)
			var hd: Vector3 = _piston_arms.call("hand_point", 0)
			_check(sh.distance_to(hd) > 1.0,
					"the arms are held OUT (%.2f m from the shoulder)"
					% sh.distance_to(hd))
			_check(absf(hd.y - sh.y) < 0.35,
					"and level, not sagging under gravity (%+.2f m)"
					% (hd.y - sh.y))
			# No fingers, no grabbing, and the plate is solid
			# (STO-CHARACTER-073).
			var fr: Node3D = _piston_arms.call("fingers_root", 0)
			_check(fr != null and not fr.visible,
					"the fingers are gone — the hands are one machine")
			var plate: Node = _piston_arms.get_node_or_null("PistonPlate")
			_check(plate is AnimatableBody3D
							and (plate as AnimatableBody3D).collision_layer != 0,
					"the plate is a SOLID body, not decoration")
			var box := _main.get_node_or_null("Playground/MovableBox")
			if box != null:
				box.global_position = _grabber.global_position \
						+ Vector3(0.0, 0.5, -1.5)
				_piston_arms.call("grab_body", 0, box, box.global_position)
				_check(not bool(_piston_arms.call("is_grabbed", 0)),
						"nothing can be grabbed in piston mode")
			_check(apart < 0.15,
					"in piston mode the hands COMBINE into one (%.3f m, was %.3f)"
					% [apart, _apart_grab])
			_next("slow")
		"slow":
			# A WEAK charge drives the arms out slowly.
			if _ticks == 1:
				_fire(0.05)
				_check(bool(_piston_arms.call("piston_firing")),
						"firing drives the ARMS out — nothing is spawned")
				return false
			if _ticks < 10:
				return false
			_slow_len = float(_grabber.call("piston_extend"))
			_check(_slow_len > 0.0,
					"the arms extended (%.2f m)" % _slow_len)
			_next("cooldown")
		"cooldown":
			if _ticks == 1:
				_grabber.set("_piston_charge", 1.6)
				_check(is_equal_approx(float(_grabber.call("fire_piston")), 0.0),
						"a second stroke is refused while on cooldown")
				return false
			if _ticks < 80:
				return false
			_check(float(_grabber.call("piston_extend")) < 0.05,
					"the arms retract all the way back (%.2f m)"
					% float(_grabber.call("piston_extend")))
			_next("fast")
		"fast":
			# A FULL charge drives them out FASTER.
			if _ticks == 1:
				_fire(1.6)
				return false
			if _ticks < 10:
				return false
			var fast_len := float(_grabber.call("piston_extend"))
			_check(fast_len > _slow_len * 1.5,
					"a full charge drives out far faster (%.2f m vs %.2f m)"
					% [fast_len, _slow_len])
			_next("aim")
		"aim":
			# ANY direction: the joined hands go where you look.
			if _ticks < 80:
				return false
			if _ticks == 80:
				var cam := _grabber.get_node("Camera3D") as Camera3D
				cam.rotation.x = deg_to_rad(80.0)
				_up_from = _piston_arms.call("hand_point", 0)
				_fire(1.6)
				return false
			if _ticks < 95:
				return false
			var now_at: Vector3 = _piston_arms.call("hand_point", 0)
			_check(now_at.y > _up_from.y + 0.3,
					"aiming up drives the hands UPWARD (%.2f -> %.2f)"
					% [_up_from.y, now_at.y])
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
