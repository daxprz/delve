extends SceneTree
## Smoke test for STO-WORLD-005: shoving an object that CAN'T move
## pushes the player back (Newton's third law). Non-hosted.
##   godot --headless -s res://tests/smoke_push_reaction.gd
## Two scenarios with the same box and the same walk into it:
##   FREE  — box in the open: it slides away, the player keeps going
##   JAMMED— box against a wall: it can't move, so the player is
##           stopped and shoved back
## Comparing the two is what proves the reaction, rather than asserting
## an absolute number that any "player stops at a box" would satisfy.

const SETTLE := 30
const PUSH_TICKS := 70

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _box: RigidBody3D
var _wall: StaticBody3D
var _start_z := 0.0
var _free_travel := 0.0
var _free_box_travel := 0.0
var _free_rebound := 0.0
var _jam_rebound := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_static_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80))
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 0  # Grabber
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_spawn_box()
			_next("free_settle")
		"free_settle":
			if _ticks < SETTLE:
				return false
			_start_z = _player.global_position.z
			Input.action_press("move_forward")   # walk into the box (-Z)
			_next("free_push")
		"free_push":
			# Track any OUTWARD (+Z) velocity while walking into the box.
			_free_rebound = maxf(_free_rebound, _player.velocity.z)
			if _ticks < PUSH_TICKS:
				return false
			Input.action_release("move_forward")
			_free_travel = _start_z - _player.global_position.z
			_free_box_travel = -2.5 - _box.global_position.z
			_check(_free_box_travel > 0.2,
					"FREE: the box slides away when pushed (%.2f m)"
					% _free_box_travel)
			_check(_free_travel > 1.0,
					"FREE: the player keeps advancing (%.2f m)" % _free_travel)
			# Rebuild jammed: box hard against a wall.
			_box.queue_free()
			_next("rebuild")
		"rebuild":
			if _ticks < 5:
				return false
			_player.global_position = Vector3(0, 1, 0)
			_player.velocity = Vector3.ZERO
			_spawn_box()
			# Wall immediately behind the box, blocking its escape.
			_wall = _static_box(Vector3(0, 2, -3.6), Vector3(12, 4, 0.3))
			_next("jam_settle")
		"jam_settle":
			if _ticks < SETTLE:
				return false
			_start_z = _player.global_position.z
			Input.action_press("move_forward")
			_next("jam_push")
		"jam_push":
			_jam_rebound = maxf(_jam_rebound, _player.velocity.z)
			if _ticks < PUSH_TICKS:
				return false
			Input.action_release("move_forward")
			var jam_travel := _start_z - _player.global_position.z
			var jam_box := -2.5 - _box.global_position.z
			_check(jam_box < _free_box_travel * 0.5,
					"JAMMED: the box barely moves (%.2f m vs %.2f m free)"
					% [jam_box, _free_box_travel])
			_check(jam_travel < _free_travel,
					"JAMMED: the player is stopped short (%.2f m vs %.2f m free)"
					% [jam_travel, _free_travel])
			# The reaction itself: while shoving the JAMMED box the
			# player must gain OUTWARD (+Z) velocity — and noticeably
			# more than when the box was free to slide.
			_check(_jam_rebound > 0.3,
					"JAMMED: the player is pushed back (peak vz=%.2f)"
					% _jam_rebound)
			_check(_jam_rebound > _free_rebound + 0.2,
					"JAMMED: rebound is caused by the blockage (%.2f vs %.2f free)"
					% [_jam_rebound, _free_rebound])
			return _finish()
	return false


func _spawn_box() -> void:
	_box = RigidBody3D.new()
	_box.mass = 2.0   # same as the playground's movable box
	_box.position = Vector3(0, 0.4, -2.5)
	var phys := PhysicsMaterial.new()
	phys.friction = 0.15
	_box.physics_material_override = phys
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3.ONE * 0.8   # same as the playground's movable box
	cs.shape = bs
	_box.add_child(cs)
	root.add_child(_box)


func _static_box(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	body.position = pos
	root.add_child(body)
	return body


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
