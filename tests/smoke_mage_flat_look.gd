extends SceneTree
## Smoke test for STO-CHARACTER-079 — from outside, he looks 2D.
##   godot --headless -s res://tests/smoke_mage_flat_look.gd
##
## Thickness is measured from the BODY ITSELF — how far apart his two
## shoulders are along the plane normal — not from a variable the code
## sets. A `thinness()` getter returning 0.04 proves the number changed;
## it proves nothing about whether anything on screen moved.
##
## The other half is the one that is easy to get wrong: he must be thin
## along the NORMAL and unchanged across the plane. A uniform shrink
## would make him thin from every angle and would pass any check that
## only measured one direction — but that is a tiny man, not a flat one.
##
## Loaded at runtime, not with a const preload — see smoke_bleeding.gd.

const PLAYER_SCENE := "res://scenes/player.tscn"
const CHARS := "res://scripts/characters.gd"

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _mage: Node
var _normal := Vector3.ZERO
var _solid_across := 0.0
var _solid_thick := 0.0
var _solid_tall := 0.0
var _names: Array = []
var _verbose := false


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
				return false
			if _ticks < 45:
				return false
			(_mage as Node3D).rotation.y = 0.0
			_check(_mage.has_method("thinness"),
					"the Mage has a thickness at all")
			_check(is_equal_approx(float(_mage.call("thinness")), 1.0),
					"and starts at full thickness (%.3f)"
					% float(_mage.call("thinness")))
			_next("measure_solid")

		"measure_solid":
			_normal = Vector3.RIGHT   # what facing -Z will give
			_solid_thick = _extent(_normal)
			_solid_across = _extent(Vector3.FORWARD)
			_solid_tall = _extent(Vector3.UP)
			print("[LOOK] solid: %.3f m thick, %.3f m across, %.3f m tall"
					% [_solid_thick, _solid_across, _solid_tall])
			_check(_solid_thick > 0.2,
					"solid, he has real thickness (%.3f m)" % _solid_thick)
			_next("flatten")

		"flatten":
			if _ticks == 1:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			# Long enough for the WARP to finish, not just for the
			# decision to be made. The warp is deliberately slow now
			# (STO-CHARACTER-082, 1.2 s), and sampling at 40 ticks caught
			# him half-warped and called it a failure to flatten.
			if _ticks < 110:
				return false
			_normal = _mage.call("plane_normal")
			_check(bool(_mage.call("is_flat")), "he flattens")
			var thin: float = float(_mage.call("thinness"))
			print("[LOOK] thinness now %.3f" % thin)
			_check(thin < 0.2, "and reports himself thin (%.3f)" % thin)

			var flat_thick := _extent(_normal)
			var flat_across := _extent(Vector3.FORWARD)
			var flat_tall := _extent(Vector3.UP)
			print("[LOOK] flat:  %.3f m thick, %.3f m across, %.3f m tall"
					% [flat_thick, flat_across, flat_tall])

			# The measurement that matters, taken off his actual body.
			_check(flat_thick < _solid_thick * 0.25,
					"his BODY really is flattened: %.3f m -> %.3f m thick"
					% [_solid_thick, flat_thick])

			# And he is flat, not small. A uniform shrink would pass the
			# check above and would be completely wrong.
			_check(flat_across > _solid_across * 0.8,
					"but just as wide ACROSS the plane (%.3f -> %.3f m) — "
					% [_solid_across, flat_across] + "he is flat, not tiny")
			_check(flat_tall > _solid_tall * 0.8,
					"and just as tall (%.3f -> %.3f m)"
					% [_solid_tall, flat_tall])
			_next("turning")

		"turning":
			# The squash belongs to the PLANE, not to him. Turning round
			# while flat must not rotate which way he is thin.
			(_mage as Node3D).rotation.y = 1.1
			if _ticks < 30:
				return false
			var still_thin := _extent(_normal)
			print("[LOOK] after turning, still %.3f m thick along the plane "
					% still_thin + "normal")
			_check(still_thin < _solid_thick * 0.25,
					"turned round, he is still thin the SAME way (%.3f m) — "
					% still_thin + "the flattening belongs to the plane")
			(_mage as Node3D).rotation.y = 0.0
			_next("back")

		"back":
			if _ticks == 1:
				Input.action_press("mage_flatten")
				return false
			if _ticks == 2:
				Input.action_release("mage_flatten")
				return false
			if _ticks < 110:
				return false
			_check(not bool(_mage.call("is_flat")), "he comes back")
			var thick := _extent(_normal)
			print("[LOOK] back to %.3f m thick (was %.3f solid)"
					% [thick, _solid_thick])
			_check(thick > _solid_thick * 0.8,
					"and is solid again, full thickness (%.3f m)" % thick)
			_check(is_equal_approx(float(_mage.call("thinness")), 1.0),
					"with no squash left on him at all")
			return _finish()
	return false


## How far his body reaches along `axis`, in metres — measured from the
## real world positions of his joints, so it can only be changed by the
## body actually moving.
func _extent(axis: Vector3) -> float:
	var body := _mage.get_node_or_null("Squash/Body")
	if body == null:
		body = _mage.get_node_or_null("Body")
	if body == null:
		return 0.0
	var pts: Array = []
	_names = []
	_gather(body, pts)
	if pts.is_empty():
		return 0.0
	var lo := INF
	var hi := -INF
	var a := axis.normalized()
	var lo_n := ""
	var hi_n := ""
	for i in pts.size():
		var d: float = (pts[i] as Vector3).dot(a)
		if d < lo:
			lo = d; lo_n = String(_names[i])
		if d > hi:
			hi = d; hi_n = String(_names[i])
	if _verbose:
		print("[EXT] extremes along %s: %s .. %s" % [str(axis), lo_n, hi_n])
	return hi - lo


func _find(n: Node, nm: String) -> Node:
	if String(n.name) == nm: return n
	for c in n.get_children():
		var r = _find(c, nm)
		if r: return r
	return null


func _gather(n: Node, into: Array) -> void:
	if n is MeshInstance3D:
		into.append((n as Node3D).global_position)
		_names.append(n.get_parent().name)
	for c in n.get_children():
		_gather(c, into)


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
