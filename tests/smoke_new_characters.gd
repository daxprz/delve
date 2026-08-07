extends SceneTree
## Smoke test for EPI-CHARACTER-NEW-CHARACTERS (STO-CHARACTER-037/038/
## 039): the three roster additions and their distinctive bodies.
##   godot --headless -s res://tests/smoke_new_characters.gd
## Non-hosted (direct instancing) so it runs during a play session.

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _db: GDScript
var _spawned: Dictionary = {}   # id -> player node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(80, 1, 80)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			_db = load("res://scripts/characters.gd")
			# Roster: the three originals plus the three new ones.
			var ids: Array = []
			for i in _db.count():
				ids.append(_db.get_def(i)["id"])
			for want in ["grabber", "runner", "flyer",
					"guardian", "sniper", "builder"]:
				_check(ids.has(want), "roster has '%s'" % want)
			_check(_db.count() == 6, "roster is 6 characters (%d)" % _db.count())

			# Spawn one of each new character, spaced apart.
			var x := 0.0
			for want in ["guardian", "sniper", "builder", "runner"]:
				_spawn(want, x)
				x += 4.0
			_phase = "check"
		"check":
			if _ticks < 60:   # let bodies build and settle
				return false

			var guardian: Node3D = _spawned["guardian"]
			var runner: Node3D = _spawned["runner"]
			var builder: Node3D = _spawned["builder"]
			var sniper: Node3D = _spawned["sniper"]

			# --- Guardian: bigger (STO-CHARACTER-037) ---
			var g_head: float = _head_height(guardian)
			var r_head: float = _head_height(runner)
			_check(g_head > r_head * 1.15,
					"Guardian is visibly bigger (head %.2f m vs Runner %.2f m)"
					% [g_head, r_head])
			var g_cap := _capsule(guardian)
			var r_cap := _capsule(runner)
			_check(g_cap.height > r_cap.height,
					"Guardian's collision capsule scaled too (%.2f vs %.2f)"
					% [g_cap.height, r_cap.height])
			_check(_cam_y(guardian) > _cam_y(runner),
					"Guardian's eye height scaled (%.2f vs %.2f)"
					% [_cam_y(guardian), _cam_y(runner)])

			# --- Builder: four arms (STO-CHARACTER-039) ---
			var b_body: Node3D = builder.get_node("Body")
			for path in ["Pelvis/Torso/ShoulderL/UpperArmL",
					"Pelvis/Torso/ShoulderR/UpperArmR",
					"Pelvis/Torso/LowerShoulderL/LowerUpperArmL",
					"Pelvis/Torso/LowerShoulderR/LowerUpperArmR"]:
				_check(b_body.get_node_or_null(path) != null,
						"Builder has arm %s" % path.get_file())
			_check(int(b_body.get("_uppers").size()) == 4,
					"Builder animates 4 arms (%d)"
					% int(b_body.get("_uppers").size()))
			var r_body: Node3D = runner.get_node("Body")
			_check(int(r_body.get("_uppers").size()) == 2,
					"Runner still has 2 arms (%d)"
					% int(r_body.get("_uppers").size()))

			# --- Sniper: ears (STO-CHARACTER-038) ---
			var s_body: Node3D = sniper.get_node("Body")
			_check(s_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarL") != null
					and s_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarR") != null,
					"Sniper has two ears")
			_check(r_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarL") == null,
					"other characters have no ears")

			# Everyone stands on the ground and is upright.
			for id in _spawned:
				var p: CharacterBody3D = _spawned[id]
				_check(p.global_position.y > -0.5 and p.global_position.y < 1.5,
						"%s rests on the ground (y=%.2f)" % [id, p.global_position.y])
			return _finish()
	return false


func _spawn(id: String, x: float) -> void:
	var idx := -1
	for i in _db.count():
		if _db.get_def(i)["id"] == id:
			idx = i
	_db.selected_index = idx
	var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	p.name = "1"   # authority
	root.add_child(p)
	p.global_position = Vector3(x, 1.0, 0.0)
	_spawned[id] = p


func _head_height(p: Node3D) -> float:
	var head: Node3D = p.get_node("Body/Pelvis/Torso/Neck/Head")
	return head.global_position.y - p.global_position.y


func _capsule(p: Node3D) -> CapsuleShape3D:
	return (p.get_node("CollisionShape3D") as CollisionShape3D).shape


func _cam_y(p: Node3D) -> float:
	return (p.get_node("Camera3D") as Camera3D).position.y


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
