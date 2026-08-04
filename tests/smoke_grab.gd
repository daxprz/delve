extends SceneTree
## Headless smoke test for STO-CHARACTER-003 grapple (rope/pendulum).
## Run with:  godot --headless -s res://tests/smoke_grab.gd
##
## Grabs a solid anchor above the player, who has sideways momentum, and
## checks it behaves like a rope pendulum:
##   - the rope holds the player within its length of the anchor
##   - momentum is kept: the player SWINGS sideways (doesn't glide to a
##     dead stop at the anchor like the old behaviour)
##   - too slow to loop over the top => the player hangs BELOW the anchor
##     (dangles), it doesn't teleport up to it
##   - release lets go
## Prints PASS/FAIL lines; exits non-zero on any FAIL.

const HOLD := 150

var _failures := 0
var _phase := "setup"
var _frames := 0
var _main: Node
var _player: CharacterBody3D
var _arms
var _anchor := Vector3.ZERO
var _rope := 0.0
var _start_x := 0.0
var _max_dist := 0.0
var _max_x := 0.0


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

	# Put the player up in the air with sideways momentum, and anchor a
	# rope 2 m above. Gravity + momentum should make it swing.
	_player.global_position = Vector3(0.0, 6.0, 0.0)
	_player.rotation = Vector3.ZERO
	_player.velocity = Vector3(5.0, 0.0, 0.0)
	_anchor = _player.global_position + Vector3(0.0, 2.0, 0.0)
	_start_x = _player.global_position.x
	_arms.grab(0, _anchor)
	_rope = _player.grapple_length
	if _arms.is_grabbed(0):
		_pass("grab engaged a rope (length %.2f m)" % _rope)
	else:
		_fail("grab did not engage")
		return false
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_phase = "swing"
		"swing":
			_frames += 1
			var d := _player.global_position.distance_to(_anchor)
			_max_dist = maxf(_max_dist, d)
			_max_x = maxf(_max_x, _player.global_position.x)
			if _frames >= HOLD:
				_check_rope()
				_check_momentum()
				_check_dangle()
				_arms.release(0)
				if not _arms.is_grabbed(0):
					_pass("release let go")
				else:
					_fail("release did not let go")
				return _done()
	return false


func _check_rope() -> void:
	if _max_dist <= _rope + 0.4:
		_pass("rope held the player within its length (max %.2f <= %.2f m)"
				% [_max_dist, _rope])
	else:
		_fail("player escaped the rope (max %.2f > %.2f m)" % [_max_dist, _rope])


func _check_momentum() -> void:
	# A kept-momentum swing moves the player sideways; the old glide-to-
	# stop would leave it near x=0.
	if _max_x - _start_x > 0.5:
		_pass("player kept momentum and swung sideways (%.2f m)"
				% [_max_x - _start_x])
	else:
		_fail("player did not swing — momentum lost (%.2f m)"
				% [_max_x - _start_x])


func _check_dangle() -> void:
	# Not enough energy to loop over => hangs below the anchor.
	if _player.global_position.y < _anchor.y - 1.0:
		_pass("player hangs below the anchor (dangles): y=%.2f, anchor.y=%.2f"
				% [_player.global_position.y, _anchor.y])
	else:
		_fail("player did not dangle below anchor (y=%.2f, anchor.y=%.2f)"
				% [_player.global_position.y, _anchor.y])


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
