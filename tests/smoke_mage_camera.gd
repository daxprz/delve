extends SceneTree
## Smoke test for STO-CHARACTER-078 — the platformer view.
##   godot --headless -s res://tests/smoke_mage_camera.gd
##
## The check the story insists on is the MIDDLE one: the camera is
## sampled partway through and has to be found partway. Testing the two
## ends would pass for a camera that cuts — and "it glides" was the
## operator's first word about it.
##
## The other one that matters is the mouse doing NOTHING while flat.
## Not "the camera is limited" — nothing. So the test shoves the mouse
## hard and asserts the view did not move a millimetre.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _mage: Node
var _cam: Camera3D
var _fp_pos := Vector3.ZERO
var _fp_fov := 0.0
var _mid_pos := Vector3.ZERO
var _mid_blend := 0.0
var _normal := Vector3.ZERO
var _flat_pos := Vector3.ZERO
var _flat_basis := Basis()
var _fp_depth := 0.0
## Where the camera sits while flat, so the slice can be checked to
## straddle the plane rather than merely being thin somewhere.
const CAM_DIST_GUESS := 22.0


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
			_cam = _mage.get_node_or_null("Camera3D")
			_check(_cam != null, "the Mage has a camera")
			if _cam == null:
				return _finish()
			(_mage as Node3D).rotation.y = 0.0
			_fp_pos = _cam.global_position
			_fp_fov = _cam.fov
			_fp_depth = _cam.far - _cam.near
			print("[CAM] first person: %.2f m from him, fov %.0f"
					% [_fp_pos.distance_to((_mage as Node3D).global_position),
					_fp_fov])
			_check(_fp_pos.distance_to(
					(_mage as Node3D).global_position) < 2.0,
					"which starts on his head, like everyone else's")
			_next("glide")

		"glide":
			if _ticks == 1:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			# Caught in the middle. A camera that cuts is never here.
			if _ticks == 30:
				_mid_blend = float(_mage.call("camera_blend"))
				_mid_pos = _cam.global_position
				print("[CAM] halfway: blend %.2f, camera %.2f m out"
						% [_mid_blend, _mid_pos.distance_to(
						(_mage as Node3D).global_position)])
				_check(_mid_blend > 0.05 and _mid_blend < 0.95,
						"caught mid-glide, it is PARTWAY there (%.2f) — it "
						% _mid_blend + "glides, it does not cut")
				return false
			if _ticks < 120:
				return false
			_normal = _mage.call("plane_normal")
			_flat_pos = _cam.global_position
			_flat_basis = _cam.global_transform.basis
			var out: float = _flat_pos.distance_to(
					(_mage as Node3D).global_position)
			print("[CAM] arrived: %.2f m out, fov %.0f" % [out, _cam.fov])
			_check(float(_mage.call("camera_blend")) > 0.99,
					"the glide finishes")
			_check(out > 5.0,
					"the camera ends up well out to the SIDE of him "
					+ "(%.2f m)" % out)
			# Out along the plane NORMAL, which is what makes it side-on
			# to the plane rather than merely third-person.
			var off: Vector3 = _flat_pos - (_mage as Node3D).global_position
			var along_normal: float = absf(off.normalized().dot(_normal))
			print("[CAM] and it is %.0f%% along the plane normal"
					% (along_normal * 100.0))
			_check(along_normal > 0.9,
					"square-on to his plane, not just behind him (%.2f)"
					% along_normal)
			# The middle really was between the two ends.
			_check(_mid_pos.distance_to(_fp_pos) > 0.2
					and _mid_pos.distance_to(_flat_pos) > 0.2,
					"and the halfway camera was between the two, not at "
					+ "either end")
			_check(_cam.fov < _fp_fov * 0.5,
					"the view narrows right down (%.0f -> %.0f), so the "
					% [_fp_fov, _cam.fov] + "world goes flat like a 2D game")
			# He should see HIS LINE and nothing else.
			var depth: float = float(_mage.call("view_depth"))
			print("[CAM] he can see a %.2f m deep slice of the world "
					% depth + "(was %.0f m)" % _fp_depth)
			_check(depth < 4.0,
					"and he can only see the plane he is ON — a %.2f m "
					% depth + "slice, not the whole world")
			_check(_cam.near < CAM_DIST_GUESS and _cam.far > CAM_DIST_GUESS,
					"with the slice centred on his own plane, not in front "
					+ "of it or behind it")
			_next("mouse")

		"mouse":
			# The mouse must do NOTHING.
			if _ticks == 1:
				var yaw_before: float = (_mage as Node3D).rotation.y
				for i in 20:
					var ev := InputEventMouseMotion.new()
					ev.relative = Vector2(120.0, 90.0)
					root.push_input(ev)
				_mouse_yaw_before = yaw_before
				return false
			if _ticks < 20:
				return false
			var moved: float = _cam.global_position.distance_to(_flat_pos)
			var turned: float = absf(
					(_mage as Node3D).rotation.y - _mouse_yaw_before)
			print("[CAM] after shoving the mouse 20 times: camera moved "
					+ "%.4f m, he turned %.4f rad" % [moved, turned])
			_check(moved < 0.05,
					"the mouse moves the camera NOT AT ALL (%.4f m)" % moved)
			_check(turned < 0.01,
					"and does not turn him either (%.4f rad)" % turned)
			_next("home")

		"home":
			if _ticks == 1:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			if _ticks == 30:
				_check(float(_mage.call("camera_blend")) < 0.95
						and float(_mage.call("camera_blend")) > 0.05,
						"it glides back too, rather than snapping home")
				return false
			if _ticks < 130:
				return false
			var back: float = _cam.global_position.distance_to(_fp_pos)
			print("[CAM] home again: %.3f m from where it started, fov %.0f"
					% [back, _cam.fov])
			_check(back < 0.2,
					"the camera comes back exactly where it was (%.3f m)"
					% back)
			_check(is_equal_approx(_cam.fov, _fp_fov),
					"with its normal view angle back (%.0f)" % _cam.fov)
			_check(float(_mage.call("view_depth")) > _fp_depth * 0.9,
					"and he can see the whole world again (%.0f m)"
					% float(_mage.call("view_depth")))
			return _finish()
	return false


var _mouse_yaw_before := 0.0


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
