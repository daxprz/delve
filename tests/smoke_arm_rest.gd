extends SceneTree
## Smoke test for STO-CHARACTER-031: pressing E (punch mode) must NOT
## raise the fists into a guard pose — the arms hang loose at the
## player's sides and only stick out while the punch button is HELD.
## Non-hosted (direct instancing) so it runs while a game is playing.
##   godot --headless -s res://tests/smoke_arm_rest.gd

const SETTLE := 90   # ticks for the Verlet arms to hang out
const REACH := 40    # ticks for an extended fist to reach

var _failures := 0
var _phase := "setup"
var _ticks := 0
var _player: CharacterBody3D
var _arms: Node
var _shoulder_y := 0.0
var _rest_y := 0.0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			# Ground so the player doesn't fall forever.
			var ground := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(40, 1, 40)
			cs.shape = bs
			ground.add_child(cs)
			ground.position = Vector3(0, -0.5, 0)
			root.add_child(ground)

			var scene: PackedScene = load("res://scenes/player.tscn")
			_player = scene.instantiate()
			_player.name = "1"  # authority for peer 1 (offline = us)
			root.add_child(_player)
			_arms = _player.get_node_or_null("MechanicalArms")
			if _arms == null:
				_fail("player has no MechanicalArms (not the Grabber?)")
				return _finish()
			_arms.set_punch_mode(true)  # what pressing E does
			_next("settle")
		"settle":
			if _ticks < SETTLE:
				return false
			_shoulder_y = _arms.call("shoulder_point", 0).y
			_rest_y = _arms.call("hand_point", 0).y
			# Hanging arms: the fist rests well BELOW the shoulder.
			_check(_rest_y < _shoulder_y - 0.3,
					"punch mode leaves the fist hanging low (fist y=%.2f vs shoulder y=%.2f)"
					% [_rest_y, _shoulder_y])
			_arms.call("set_extended", 0, true)
			_next("reach")
		"reach":
			if _ticks < REACH:
				return false
			var out_y: float = _arms.call("hand_point", 0).y
			var fist: Vector3 = _arms.call("hand_point", 0)
			var shoulder: Vector3 = _arms.call("shoulder_point", 0)
			var horiz := Vector3(fist.x - shoulder.x, 0.0, fist.z - shoulder.z)
			_check(out_y > _rest_y + 0.2,
					"holding the punch button raises the fist (y %.2f -> %.2f)"
					% [_rest_y, out_y])
			_check(horiz.length() > 0.5,
					"extended fist reaches out in front (%.2f m)" % horiz.length())
			_arms.call("set_extended", 0, false)
			_next("drop")
		"drop":
			if _ticks < REACH:
				return false
			var back_y: float = _arms.call("hand_point", 0).y
			_check(back_y < _shoulder_y - 0.3,
					"releasing drops the fist back down (y=%.2f)" % back_y)
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


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
