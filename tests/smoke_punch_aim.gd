extends SceneTree
## Smoke test for STO-CHARACTER-046: punches follow the camera's aim,
## including up and down. Non-hosted so it runs during play.
##   godot --headless -s res://tests/smoke_punch_aim.gd
## Before this, _reach_point used the player BODY's facing flattened to
## the horizon, so every punch came out level no matter where you
## looked.

const SETTLE := 40
const REACH := 30

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _arms: Node
var _cam: Camera3D
var _level_y := 0.0
var _up_y := 0.0
var _enemy: CharacterBody3D


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			_sb(Vector3(0, -0.5, 0), Vector3(80, 1, 80))
			var db: GDScript = load("res://scripts/characters.gd")
			db.selected_index = 0   # Grabber
			_player = load("res://scenes/player.tscn").instantiate()
			_player.name = "1"
			_player.position = Vector3(0, 1, 0)
			root.add_child(_player)
			_arms = _player.get_node_or_null("MechanicalArms")
			_cam = _player.get_node("Camera3D")
			if _arms == null:
				_check(false, "Grabber has arms")
				return _finish()
			_arms.call("set_punch_mode", true)
			_arms.call("set_extended", 0, true)
			_next("level")
		"level":
			if _ticks < SETTLE:
				return false
			_level_y = _arms.call("hand_point", 0).y
			_cam.rotation.x = deg_to_rad(55.0)    # look UP
			_next("aim_up")
		"aim_up":
			if _ticks < REACH:
				return false
			_up_y = _arms.call("hand_point", 0).y
			_check(_up_y > _level_y + 0.4,
					"aiming up raises the punch (%.2f m -> %.2f m)"
					% [_level_y, _up_y])
			_cam.rotation.x = deg_to_rad(-55.0)   # look DOWN
			_next("aim_down")
		"aim_down":
			if _ticks < REACH:
				return false
			var down_y: float = _arms.call("hand_point", 0).y
			_check(down_y < _level_y - 0.3,
					"aiming down lowers the punch (%.2f m -> %.2f m)"
					% [_level_y, down_y])
			_check(down_y < _up_y - 1.0,
					"up and down punches are far apart (%.2f m)" % (_up_y - down_y))
			# An upward punch must LAUNCH an enemy upward.
			_cam.rotation.x = deg_to_rad(50.0)
			var es: GDScript = load("res://scripts/enemy.gd")
			_enemy = es.new()
			_enemy.name = "Uppercut"
			_enemy.position = Vector3(0, 1, -1.0)
			root.add_child(_enemy)
			# Force the STURDIEST possible build, so this proves a punch
			# floors even the toughest enemy rather than riding on which
			# body the random seed happened to generate.
			_enemy.set("_mass", 1.5)
			_enemy.set("_stability", 1.25)
			_player.set_physics_process(false)
			_next("uppercut")
		"uppercut":
			_player.velocity = Vector3(0, 0, -6.0)
			var fist: Vector3 = _arms.call("hand_point", 0)
			if not _enemy.is_downed():
				_enemy.global_position = fist - Vector3(0, 0.8, 0)
			if _ticks < 30:
				return false
			_check(_enemy.is_downed(), "an aimed-up punch still connects")
			var rag: Node3D = _enemy.ragdoll()
			if rag != null:
				var torso: RigidBody3D = rag.call("part", "Torso")
				_check(torso != null and torso.linear_velocity.y > 1.0,
						"an upward punch launches them UP (vy=%.1f)"
						% (torso.linear_velocity.y if torso else 0.0))
			else:
				_check(false, "no ragdoll after the uppercut")
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
