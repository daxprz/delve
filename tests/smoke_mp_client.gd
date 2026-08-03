extends SceneTree
## Multiplayer smoke test — CLIENT side (STO-CORE-003).
## Run via scripts/run_mp_test.sh (pairs with smoke_mp_host.gd).
##
## Joins 127.0.0.1, then verifies:
##   - own player node spawns (replicated from the server)
##   - the HOST's player node (Players/1) is visible locally
##   - injected move_forward moves own player (authority works)
## Quits when done; the host treats our disconnect as end-of-test.
## Exits 0 on PASS, 1 on FAIL. Budgeted in physics ticks (60/s).

const MAX_TICKS := 900  # 15 s overall budget
const MOVE_TICKS := 60

var _main: Node
var _ticks := 0
var _phase_ticks := 0
var _failures := 0
var _phase := "setup"
var _me: CharacterBody3D
var _start_z := 0.0


func _physics_process(_delta: float) -> bool:
	if _phase == "setup":
		# Setup on first tick, not _initialize — autoloads join the
		# tree only after _initialize returns (godot-headless-testing).
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_main.join_game()
		print("CLIENT: joining 127.0.0.1")
		_phase = "wait_spawn"
		return false

	_ticks += 1
	if _ticks > MAX_TICKS:
		_fail("timeout in phase '%s'" % _phase)
		return _finish()

	match _phase:
		"wait_spawn":
			var my_id := root.multiplayer.get_unique_id()
			if my_id > 1:
				_me = _main.get_node_or_null("Players/%d" % my_id) as CharacterBody3D
				if _me != null:
					_pass("own player spawned (peer id %d)" % my_id)
					if _main.get_node_or_null("Players/1") != null:
						_pass("host player visible at Players/1")
					else:
						_fail("host player NOT visible at Players/1")
					_start_z = _me.position.z
					Input.action_press("move_forward")
					_phase_ticks = 0
					_phase = "move"
		"move":
			_phase_ticks += 1
			if not is_instance_valid(_me):
				_fail("own player was freed mid-move (server gone?)")
				return _finish()
			if _phase_ticks >= MOVE_TICKS:
				Input.action_release("move_forward")
				var dz := _me.position.z - _start_z
				if dz < -1.0:
					_pass("own movement works under authority (dz=%.2f)" % dz)
				else:
					_fail("player did not move (dz=%.2f)" % dz)
				# Finish immediately — the host outlives us and treats
				# our disconnect as the end-of-test signal.
				return _finish()
	return false


func _finish() -> bool:
	print("CLIENT RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
