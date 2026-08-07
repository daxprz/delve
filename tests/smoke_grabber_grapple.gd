extends SceneTree
## Smoke test for STO-CHARACTER-044 — the Grabber's grab does three
## things it previously didn't. Non-hosted, so it runs during play.
##   godot --headless -s res://tests/smoke_grabber_grapple.gd
##
##   1. grabbing something SOLID pulls the PLAYER toward it (grapple)
##   2. grabbing an ENEMY makes it go limp (ragdoll) and holds it
##   3. a held enemy stays limp until released, then recovers

const SETTLE := 40
const PULL_TICKS := 45

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _arms: Node
var _enemy: CharacterBody3D
var _anchor := Vector3(0, 2.0, -9.0)
var _start_z := 0.0
var _held_part: RigidBody3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_sb(Vector3(0, -0.5, 0), Vector3(80, 1, 80))
			_sb(Vector3(0, 2, -10.0), Vector3(20, 4, 0.3))   # wall to grab
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 0   # Grabber
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			_player.position = Vector3(0, 1, 0)
			root.add_child(_player)
			_arms = _player.get_node_or_null("MechanicalArms")
			_check(_arms != null, "Grabber has mechanical arms")
			if _arms == null:
				return _finish()
			_next("grapple")
		"grapple":
			if _ticks < SETTLE:
				return false
			# Grab the wall dead ahead and hold on.
			_start_z = _player.global_position.z
			_arms.call("grab_target", 0, null, _anchor)
			_next("grapple_pull")
		"grapple_pull":
			if _ticks < PULL_TICKS:
				return false
			var travelled := _start_z - _player.global_position.z
			_check(travelled > 1.5,
					"grabbing something solid hauls the player toward it (%.2f m)"
					% travelled)
			_check(_player.velocity.z < -1.0,
					"the player is still being reeled in (vz=%.2f)"
					% _player.velocity.z)
			_arms.call("release", 0)
			# Now an enemy, right in front.
			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "Victim"
			_enemy.position = _player.global_position + Vector3(0, 0, -2.0)
			root.add_child(_enemy)
			_next("enemy_settle")
		"enemy_settle":
			if _ticks < 30:
				return false
			_check(not _enemy.is_downed(), "the enemy starts on its feet")
			_arms.call("grab_target", 0, _enemy, _enemy.global_position)
			_next("enemy_grabbed")
		"enemy_grabbed":
			if _ticks < 3:
				return false
			_check(_enemy.is_downed(),
					"grabbing an enemy makes it go limp (ragdolled)")
			_check(_enemy.is_held_ragdoll(), "the enemy is held")
			_check(_arms.call("grabbed_enemy", 0) == _enemy,
					"the arm knows which enemy it holds")
			_held_part = _arms.call("grabbed_body", 0)
			_check(_held_part is RigidBody3D,
					"the arm holds a real ragdoll part (%s)" % str(_held_part))
			_next("stay_limp")
		"stay_limp":
			# A ragdoll normally gets up after ~2 s; a HELD one must not.
			if _ticks < 200:
				return false
			_check(_enemy.is_downed(),
					"a held enemy stays limp instead of getting up")
			_arms.call("release", 0)
			_next("released")
		"released":
			if _ticks < 3:
				return false
			_check(not _enemy.is_held_ragdoll(),
					"releasing lets the enemy go")
			_check(_arms.call("grabbed_enemy", 0) == null,
					"the arm forgets the enemy it dropped")
			_next("recovers")
		"recovers":
			if _enemy.is_downed():
				if _ticks > 600:
					_check(false, "a dropped enemy never got back up")
					return _finish()
				return false
			_check(true, "a dropped enemy gets back up on its own")
			return _finish()
	return false


func _sb(pos: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = pos
	root.add_child(b)


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
