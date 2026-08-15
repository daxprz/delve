extends SceneTree
## Smoke test for STO-CHARACTER-038 (the Sniper's body). Non-hosted.
##   godot --headless -s res://tests/smoke_sniper_body.gd
## The Guardian and Builder were removed on 2026-08-07, so this also
## guards that the roster is back to four and that no leftovers of
## those two remain (no oversized bodies, no second pair of arms).

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _db: GDScript
var _sniper: CharacterBody3D
var _runner: CharacterBody3D


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
			var ids: Array = []
			for i in _db.count():
				ids.append(_db.get_def(i)["id"])
			for want in ["grabber", "runner", "flyer", "sniper", "mage"]:
				_check(ids.has(want), "roster has '%s'" % want)
			for gone in ["guardian", "builder"]:
				_check(not ids.has(gone), "'%s' is gone from the roster" % gone)
			# The Mage joined on 2026-08-14 (EPI-CHARACTER-MAGE-FLATLANDER).
			# The count is asserted rather than left open because the two
			# removed characters above were removed on purpose, and a
			# roster that silently regrows is worth catching.
			_check(_db.count() == 5, "roster is 5 characters (%d)" % _db.count())

			_sniper = _spawn("sniper", 0.0)
			_runner = _spawn("runner", 4.0)
			_phase = "check"
		"check":
			if _ticks < 60:
				return false
			var s_body: Node3D = _sniper.call("body_node")
			var r_body: Node3D = _runner.call("body_node")

			# Ears — the Sniper's one body feature.
			_check(s_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarL") != null
					and s_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarR") != null,
					"Sniper has two ears")
			_check(r_body.get_node_or_null("Pelvis/Torso/Neck/Head/EarL") == null,
					"other characters have no ears")

			# No leftovers from the removed characters.
			_check(int(s_body.get("_uppers").size()) == 2,
					"Sniper has the normal 2 arms (%d)"
					% int(s_body.get("_uppers").size()))
			_check(s_body.get_node_or_null("Pelvis/Torso/LowerShoulderL") == null,
					"no second pair of arms remains anywhere")
			var s_head: float = _head_height(_sniper)
			var r_head: float = _head_height(_runner)
			_check(absf(s_head - r_head) < 0.35,
					"no oversized bodies remain (Sniper %.2f m vs Runner %.2f m)"
					% [s_head, r_head])

			for p in [_sniper, _runner]:
				_check(p.global_position.y > -0.5 and p.global_position.y < 1.5,
						"%s rests on the ground" % p.character_id())
			return _finish()
	return false


func _spawn(id: String, x: float) -> CharacterBody3D:
	for i in _db.count():
		if _db.get_def(i)["id"] == id:
			_db.selected_index = i
	var p: CharacterBody3D = load("res://scenes/player.tscn").instantiate()
	p.name = "1"
	# Position BEFORE entering the tree, exactly as main.gd does —
	# otherwise the new body materialises at the origin inside whoever
	# spawned there first and shoves them into the air.
	p.position = Vector3(x, 1.0, 0.0)
	root.add_child(p)
	return p


func _head_height(p: Node3D) -> float:
	var head: Node3D = p.get_node("Body/Pelvis/Torso/Neck/Head")
	return head.global_position.y - p.global_position.y


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
