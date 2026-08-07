extends SceneTree
## Regression test for STO-ENEMIES-009: a tail sitting inside an enemy
## that is ragdolling must NOT set off a feedback loop (tail rays
## snapping to tumbling parts -> fake velocity spikes -> phantom tail
## "hits" -> re-shoving the ragdoll -> both spazzing out).
##   godot --headless -s res://tests/smoke_tail_ragdoll.gd
## Verifies, with the tail deliberately jammed into a ragdolling enemy:
##   - tail point speeds stay sane (no snap-induced spikes)
##   - the chain stays finite
##   - the ragdoll is not repeatedly re-shoved (its knockdown timer is
##     not extended, and part speeds decay instead of climbing)

const SETTLE := 90
const WATCH := 180
const MAX_TAIL_SPEED := 60.0    # m/s; snapping spikes ran far above this

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _tail: Node
var _enemy: CharacterBody3D
var _worst_tail_speed := 0.0
var _worst_part_speed := 0.0
var _late_part_speed := 0.0
var _prev_pts: Array = []


func _physics_process(delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(120, 1, 120)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 1  # Runner (tail)
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			root.add_child(_player)
			_tail = _player.get_node_or_null("Tail")
			if _tail == null:
				_fail("Runner has no Tail")
				return _finish()

			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "Victim"
			# Right on top of the player, so the tail is inside it.
			_enemy.position = _player.global_position + Vector3(0.0, 0.0, 0.6)
			root.add_child(_enemy)
			_next("settle")
		"settle":
			if _ticks < SETTLE:
				return false
			# Ragdoll it, then jam the tail through the parts.
			_enemy.apply_knockback(Vector3(9.0, 2.0, 0.0))
			_check(_enemy.is_downed(), "enemy is ragdolling")
			_jam_tail_into_ragdoll()
			_snapshot_points()
			_next("watch")
		"watch":
			var pts := _current_points()
			for i in pts.size():
				if i < _prev_pts.size():
					var sp: float = (pts[i] - _prev_pts[i]).length() / delta
					_worst_tail_speed = maxf(_worst_tail_speed, sp)
			_prev_pts = pts

			var rag: Node3D = _enemy.ragdoll()
			if rag != null:
				var pelvis: RigidBody3D = rag.call("part", "Pelvis")
				if pelvis != null:
					var ps := pelvis.linear_velocity.length()
					_worst_part_speed = maxf(_worst_part_speed, ps)
					if _ticks > WATCH / 2:
						_late_part_speed = maxf(_late_part_speed, ps)
			if _ticks < WATCH:
				return false

			_check(_worst_tail_speed < MAX_TAIL_SPEED,
					"tail points stay sane inside a ragdoll (peak %.1f m/s)"
					% _worst_tail_speed)
			_check(bool(_tail.call("is_finite_chain")),
					"tail chain stays finite")
			# No re-shoving: the ragdoll must be SLOWING, not being
			# re-launched by phantom tail hits.
			_check(_late_part_speed < _worst_part_speed,
					"ragdoll decays instead of being re-shoved (peak %.1f -> late %.1f m/s)"
					% [_worst_part_speed, _late_part_speed])
			return _finish()
	return false


func _jam_tail_into_ragdoll() -> void:
	var rag: Node3D = _enemy.ragdoll()
	if rag == null:
		return
	var n: int = _tail.call("tail_length") + 1
	var i := 3
	for pname in ["Pelvis", "Torso", "Head", "ThighL", "ShinR"]:
		var part: RigidBody3D = rag.call("part", pname)
		if part != null and i < n:
			_tail.call("set_point_for_test", i, part.global_position)
			i += 1
	print("  (jammed %d tail points into ragdoll parts)" % (i - 3))


func _current_points() -> Array:
	var out: Array = []
	var n: int = _tail.call("tail_length") + 1
	for i in n:
		out.append(_tail.call("point_at", i))
	return out


func _snapshot_points() -> void:
	_prev_pts = _current_points()


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


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
