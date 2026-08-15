extends SceneTree
## Smoke test for STO-CHARACTER-076 — press F and step into the 2nd
## dimension.
##   godot --headless -s res://tests/smoke_mage_flatten.gd
##
## The load-bearing check is the COMPARISON: walking along the plane
## has to work while walking off it does not. Checking only that he
## cannot move sideways would pass for a Mage who cannot move at all,
## and a flat man frozen to the spot is not the ability that was asked
## for.
##
## The second one that matters is that the plane STAYS PUT when he
## turns. A plane that re-chose itself every frame would not be a place
## — it would just be a strange way of walking — and every other check
## here would pass for it.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _mage: Node
var _runner: Node
var _normal_at_press := Vector3.ZERO
var _origin_at_press := Vector3.ZERO
var _start := Vector3.ZERO
var _along_plane := 0.0
var _key_start := Vector3.ZERO
var _d_moved := Vector3.ZERO
var _a_moved := Vector3.ZERO


func _spawn(id: String, nm: String) -> Node:
	var db = load(CHARS)
	for i in int(db.count()):
		if String(db.get_def(i)["id"]) == id:
			db.selected_index = i
	var p: CharacterBody3D = (load(PLAYER_SCENE) as PackedScene).instantiate()
	p.name = nm
	_main.get_node("Players").add_child(p)
	return p


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				_mage = _spawn("mage", "1")
				_runner = _spawn("runner", "2")
				return false
			if _ticks < 45:      # land on the floor first
				return false
			# The spider out of the way. It hunts by radar now
			# (STO-ENEMIES-038) and will happily grab the Mage in the
			# middle of a measurement — being taken suspends the plane,
			# so the test would report the flattening as broken when the
			# real story was that a monster carried the subject off.
			for e in _main.get_node("Enemies").get_children():
				(e as Node3D).global_position = Vector3(0.0, 0.0, 600.0)
			for d in get_nodes_in_group("dummies"):
				(d as Node3D).global_position = Vector3(0.0, 0.0, 620.0)
			_check(bool(_mage.call("can_flatten")),
					"the Mage can step into the second dimension")
			_check(not bool(_runner.call("can_flatten")),
					"and nobody else can — it is his trick")
			_check(not bool(_mage.call("is_flat")),
					"he starts solid")
			# The negative case, up front: asking a Runner to flatten
			# must not work, whatever anyone calls.
			_check(not bool(_runner.call("flatten")),
					"a Runner asked to flatten refuses")
			_check(not bool(_runner.call("is_flat")),
					"and stays solid")
			_next("press")

		"press":
			# The real key, not the function. Driving the function is
			# not driving the feature.
			if _ticks == 1:
				_check(InputMap.has_action("mage_flatten"),
						"there is a key bound to flattening")
				(_mage as Node3D).rotation.y = 0.0   # facing -Z
				_start = (_mage as Node3D).global_position
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			if _ticks < 8:
				return false
			_check(bool(_mage.call("is_flat")),
					"pressing the key flattens him")
			_normal_at_press = _mage.call("plane_normal")
			_origin_at_press = _mage.call("plane_origin")
			print("[FLAT] plane normal %.2f, %.2f, %.2f"
					% [_normal_at_press.x, _normal_at_press.y,
					_normal_at_press.z])
			# Everything IN FRONT of him is the plane, so the plane
			# contains his forward direction — which means the normal is
			# square to it.
			var fwd: Vector3 = -(_mage as Node3D).global_transform.basis.z
			fwd.y = 0.0
			var dot: float = absf(_normal_at_press.dot(fwd.normalized()))
			print("[FLAT] normal vs the way he was facing: dot %.4f" % dot)
			_check(dot < 0.05,
					"the plane is the one he was FACING (dot %.4f)" % dot)
			_check(absf(_normal_at_press.y) < 0.01,
					"and it is upright — looking up cannot tilt his world")
			_next("turn")

		"turn":
			# Turning must NOT move the plane.
			(_mage as Node3D).rotation.y = 1.2
			if _ticks < 20:
				return false
			var n2: Vector3 = _mage.call("plane_normal")
			var o2: Vector3 = _mage.call("plane_origin")
			print("[FLAT] after turning 69 degrees, normal %.2f, %.2f, %.2f"
					% [n2.x, n2.y, n2.z])
			_check(n2.distance_to(_normal_at_press) < 0.01,
					"turning does NOT move the plane — it is a place, not "
					+ "a direction")
			_check(o2.distance_to(_origin_at_press) < 0.01,
					"and its origin stays put too")
			(_mage as Node3D).rotation.y = 0.0
			_next("walk_off")

		"walk_off":
			# Every walk key, including the ones that used to push him
			# off the plane. Since the controls were remapped for the
			# platformer (D forward, A back, W/S nothing) there is no
			# longer any key that even ASKS to leave the plane — so this
			# phase is now weak on its own, and the real weight is
			# carried by "shoved" below, where something else pushes him.
			if _ticks == 1:
				Input.action_press("move_right")
				Input.action_press("move_forward")
				return false
			if _ticks < 80:
				return false
			Input.action_release("move_right")
			Input.action_release("move_forward")
			var off: float = _mage.call("distance_off_plane",
					(_mage as Node3D).global_position)
			print("[FLAT] after 80 ticks holding every walk key, %.4f m off "
					% off + "the plane")
			_check(off < 0.05,
					"he cannot walk off his own plane (%.4f m)" % off)
			_next("shoved")

		"shoved":
			# SOMETHING ELSE moves him off the plane — a shove, a lift,
			# a slide resolved along a wall. Refusing to walk off is not
			# enough; he has to be PUT BACK.
			#
			# This case exists because sabotaging the projection alone
			# left every other check in this file passing: walking is
			# covered by never building the velocity in the first place,
			# so the correction had no test of its own at all.
			if _ticks == 1:
				(_mage as Node3D).global_position += \
						_normal_at_press * 3.0
				var pushed: float = _mage.call("distance_off_plane",
						(_mage as Node3D).global_position)
				print("[FLAT] shoved %.2f m off the plane" % pushed)
				_check(pushed > 1.0,
						"the shove really moved him (%.2f m)" % pushed)
				return false
			if _ticks < 20:
				return false
			var off: float = _mage.call("distance_off_plane",
					(_mage as Node3D).global_position)
			print("[FLAT] one moment later, %.4f m off the plane" % off)
			_check(off < 0.05,
					"shoved off his plane, he is PUT BACK on it (%.4f m)"
					% off)
			_next("walk_along")

		"walk_along":
			# ...but along it he moves perfectly well. Without this, a
			# Mage frozen solid would pass everything above.
			if _ticks == 1:
				_start = (_mage as Node3D).global_position
				# D, not W: the controls are a platformer's now.
				Input.action_press("move_right")
				return false
			if _ticks < 80:
				return false
			Input.action_release("move_right")
			var moved: Vector3 = (_mage as Node3D).global_position - _start
			_along_plane = moved.length()
			var off: float = _mage.call("distance_off_plane",
					(_mage as Node3D).global_position)
			print("[FLAT] walking ALONG the plane moved him %.2f m, still "
					% _along_plane + "%.4f m off it" % off)
			_check(_along_plane > 1.0,
					"but he walks along it perfectly well (%.2f m)"
					% _along_plane)
			_check(off < 0.05,
					"and never leaves it doing so (%.4f m)" % off)
			_next("platformer_keys")

		"platformer_keys":
			# D forward, A backward, W/S nothing (operator, 2026-08-14).
			if _ticks == 1:
				# Put back where he flattened first. The previous phase
				# walked him until he met something, so testing D from
				# there measured a man against a wall and reported 0.00 m
				# — which looks exactly like the key not working.
				(_mage as Node3D).global_position = _origin_at_press
				(_mage as CharacterBody3D).velocity = Vector3.ZERO
				return false
			if _ticks == 5:
				_key_start = (_mage as Node3D).global_position
				Input.action_press("move_right")
				return false
			if _ticks == 65:
				Input.action_release("move_right")
				_d_moved = (_mage as Node3D).global_position - _key_start
				_key_start = (_mage as Node3D).global_position
				Input.action_press("move_left")
				return false
			if _ticks == 125:
				Input.action_release("move_left")
				_a_moved = (_mage as Node3D).global_position - _key_start
				_key_start = (_mage as Node3D).global_position
				Input.action_press("move_forward")
				return false
			if _ticks < 185:
				return false
			Input.action_release("move_forward")
			var w_moved: float = (_mage as Node3D).global_position \
					.distance_to(_key_start)
			var along := Vector3.UP.cross(_normal_at_press).normalized()
			var d_along: float = _d_moved.dot(along)
			var a_along: float = _a_moved.dot(along)
			print("[FLAT] D moved %.2f m along the plane, A moved %.2f m, "
					% [d_along, a_along] + "W moved %.2f m in total"
					% w_moved)
			_check(absf(d_along) > 1.0,
					"D moves him along the plane (%.2f m)" % d_along)
			# The comparison that matters: A must be the OTHER way, not
			# merely "also some movement". A test of D alone would pass
			# for a Mage who only ever goes one way.
			_check(a_along * d_along < 0.0,
					"and A moves him the OPPOSITE way (%.2f vs %.2f)"
					% [a_along, d_along])
			_check(w_moved < 0.5,
					"while W does nothing — the direction it used to mean "
					+ "is the one that no longer exists (%.2f m)" % w_moved)
			_next("back")

		"back":
			# He comes back HERE, not where he went in.
			#
			# Walked away from the entrance FIRST. The key phase above
			# resets him to where he flattened and then moves him equally
			# each way, so without this he would be standing exactly at
			# the entrance and "he came back somewhere else" would be
			# testing nothing.
			if _ticks == 1:
				Input.action_press("move_right")
				return false
			if _ticks == 60:
				Input.action_release("move_right")
				_start = (_mage as Node3D).global_position
				Input.action_press("mage_flatten")
				return false
			if _ticks == 61:
				Input.action_release("mage_flatten")
				return false
			if _ticks < 90:
				return false
			_check(not bool(_mage.call("is_flat")),
					"pressing again brings him back")
			var drift: float = (_mage as Node3D).global_position \
					.distance_to(_start)
			print("[FLAT] came back %.2f m from where he was when he pressed"
					% drift)
			_check(drift < 1.5,
					"he comes back WHERE HE IS, not where he went in "
					+ "(%.2f m)" % drift)
			_check(_origin_at_press.distance_to(
					(_mage as Node3D).global_position) > 1.0,
					"which is somewhere else entirely from the entrance "
					+ "(%.2f m away)" % _origin_at_press.distance_to(
					(_mage as Node3D).global_position))
			_next("free")

		"free":
			# Solid again, he can move in every direction once more.
			if _ticks == 1:
				_start = (_mage as Node3D).global_position
				Input.action_press("move_right")
				return false
			if _ticks < 60:
				return false
			Input.action_release("move_right")
			var sideways: float = absf(
					((_mage as Node3D).global_position - _start)
					.dot(_normal_at_press))
			print("[FLAT] solid again, moved %.2f m along the old normal"
					% sideways)
			_check(sideways > 0.5,
					"solid again, the direction that was forbidden works "
					+ "(%.2f m)" % sideways)
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
