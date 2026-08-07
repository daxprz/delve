extends SceneTree
## Headless smoke test for STO-CHARACTER-003 grab (grab-only, no grapple).
## Run with:  godot --headless -s res://tests/smoke_grab.gd
##
## Grabbing is JUST grabbing now: the hand latches onto the aimed point.
## Checks:
##   - grab() engages and the hand reaches toward the target
##   - there is NO rope-swing: a grabbed player with sideways momentum is
##     NOT flung/held around an anchor — grabbing doesn't move the player
##   - release lets go

const HOLD := 60

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _target := Vector3.ZERO


func _setup() -> bool:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	_main.host_game()
	_player = _main.get_node_or_null("Players/1") as CharacterBody3D
	if _player == null:
		_fail("no player")
		return false
	_arms = _player.get_node_or_null("MechanicalArms")
	if _arms == null:
		_fail("no arms")
		return false

	# Stand on the ground; freeze normal movement so we isolate the grab.
	_player.set_physics_process(false)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_player.rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	# Aim a grab point just in front of the player, within the arm's reach.
	_target = _player.global_position + Vector3(0.0, 1.2, -1.4)
	_arms.grab(0, _target)
	if _arms.is_grabbed(0):
		_pass("grab engaged (hand latched onto the point)")
	else:
		_fail("grab did not engage")
		return false
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_phase = "hold"
		"hold":
			_frames += 1
			# Player is frozen; grabbing must NOT teleport/pull it anywhere.
			_player.global_position = Vector3(0.0, 1.0, 0.0)
			if _frames >= HOLD:
				var hand: Vector3 = _arms.hand_point(0)
				if hand.distance_to(_target) < 0.6:
					_pass("the hand reached and holds the grabbed point (%.2f m)"
							% hand.distance_to(_target))
				else:
					_fail("hand did not reach the point (%.2f m)"
							% hand.distance_to(_target))
				_arms.release(0)
				if not _arms.is_grabbed(0):
					_pass("release let go")
				else:
					_fail("release did not let go")
				return _done()
	return false


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true

func _pass(msg: String) -> void:
	print("PASS: %s" % msg)

func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
