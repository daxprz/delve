extends SceneTree
## Headless smoke test for STO-ENEMIES-003 (procedural enemy bodies).
##   godot --headless -s res://tests/smoke_enemy_body.gd
## No networking needed — enemies are instanced directly. Verifies:
##   - enemies build a humanoid Body (pelvis/torso/neck/head + legs)
##   - different names -> different proportions (procedural variation)
##   - same name -> identical proportions (deterministic, MP-safe)
##   - damage flash retints and restores the body material
## Exits 0 on PASS, 1 on FAIL.

# NOTE: no preload here — the main-loop script compiles before
# autoloads exist, and enemy.gd references DebugOverlay. load() at
# runtime instead (godot-headless-testing gotcha).
const SCALE_KEYS := ["_leg_scale", "_arm_scale", "_torso_scale", "_head_scale", "_bulk"]

var _enemy_script: GDScript

var _failures := 0
var _phase := "setup"
var _flash_ticks := 0
var _a: CharacterBody3D
var _b: CharacterBody3D
var _c: CharacterBody3D


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			# Setup on first tick, not _initialize (godot-headless-testing).
			_enemy_script = load("res://scripts/enemy.gd")
			var holder_a := Node3D.new()
			var holder_b := Node3D.new()
			root.add_child(holder_a)
			root.add_child(holder_b)
			_a = _spawn(holder_a, "Enemy0")
			_b = _spawn(holder_a, "Enemy1")
			_c = _spawn(holder_b, "Enemy0")  # same name as _a, other parent
			_phase = "check"
		"check":
			var body_a := _a.get_node_or_null("Body")
			_check(body_a != null, "enemy builds a Body node")
			if body_a == null:
				return _finish()
			for part in ["Pelvis", "Pelvis/Torso", "Pelvis/Torso/Neck/Head",
					"Pelvis/HipL/ThighL/ShinL/FootL", "Pelvis/HipR/ThighR/ShinR/FootR"]:
				_check(body_a.get_node_or_null(part) != null, "Body has %s" % part)
			_check(int(body_a.call("joint_count")) >= 15,
					"Body has a full joint set (%d)" % int(body_a.call("joint_count")))
			_check(not bool(body_a.call("uses_fade_shader")),
					"enemy body does not use the first-person fade shader")
			_check(body_a.get_node_or_null("Pelvis/Torso/Neck/Head").get_child_count() >= 2,
					"head has eyes")

			# Variation: Enemy0 vs Enemy1 differ in at least one proportion.
			var body_b := _b.get_node("Body")
			var differs := false
			for k in SCALE_KEYS:
				if absf(float(body_a.get(k)) - float(body_b.get(k))) > 0.001:
					differs = true
			_check(differs, "different names -> different proportions")

			# Determinism: same name -> identical proportions.
			var body_c := _c.get_node("Body")
			var same := true
			for k in SCALE_KEYS:
				if absf(float(body_a.get(k)) - float(body_c.get(k))) > 0.0001:
					same = false
			_check(same, "same name -> identical proportions (MP-safe)")

			# No damage flash (STO-ENEMIES-007): tint must NOT change on
			# hit — the physical reaction is the feedback.
			var mat: StandardMaterial3D = _find_material(body_a)
			var before := mat.albedo_color
			_a.take_damage(5.0)
			_check(mat.albedo_color == before,
					"damage does NOT retint the body (no white flash)")
			return _finish()
	return false


func _spawn(parent: Node, enemy_name: String) -> CharacterBody3D:
	var e: CharacterBody3D = _enemy_script.new()
	e.name = enemy_name
	parent.add_child(e)
	return e


func _find_material(body: Node) -> StandardMaterial3D:
	var pelvis_mesh: MeshInstance3D = body.get_node("Pelvis").get_child(0)
	return pelvis_mesh.material_override as StandardMaterial3D


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
