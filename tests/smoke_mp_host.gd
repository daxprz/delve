extends SceneTree
## Multiplayer smoke test — HOST side (STO-CORE-003).
## Run via scripts/run_mp_test.sh (pairs with smoke_mp_client.gd).
##
## Hosts on the default port, then verifies:
##   - a client peer connects
##   - a player node spawns for that peer under Players/
##   - the client player's movement replicates (z decreases)
## Exits 0 on PASS, 1 on FAIL. Budgeted in physics ticks (60/s).

const MAX_TICKS := 900  # 15 s overall budget

var _main: Node
var _ticks := 0
var _failures := 0
var _phase := "setup"
var _client_id := 0
var _client_player: Node3D
var _client_start_z := 0.0


func _physics_process(_delta: float) -> bool:
	if _phase == "setup":
		# Setup on first tick, not _initialize — autoloads join the
		# tree only after _initialize returns (godot-headless-testing).
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_main.host_game()
		_main.start_game()   # the lobby no longer starts the game for you
		print("HOST: hosting, waiting for client")
		_phase = "wait_client"
		return false

	_ticks += 1
	if _ticks > MAX_TICKS:
		_fail("timeout in phase '%s'" % _phase)
		return _finish()

	match _phase:
		"wait_client":
			var peers := root.multiplayer.get_peers()
			if peers.size() > 0:
				_client_id = peers[0]
				_pass("client peer connected (id %d)" % _client_id)
				_phase = "wait_spawn"
		"wait_spawn":
			_client_player = _main.get_node_or_null(
					"Players/%d" % _client_id) as Node3D
			if _client_player != null:
				_client_start_z = _client_player.position.z
				_pass("client player spawned at Players/%d" % _client_id)
				_phase = "watch_move"
		"watch_move":
			if not is_instance_valid(_client_player):
				_fail("client player freed before movement was observed")
				return _finish()
			var dz := _client_player.position.z - _client_start_z
			if dz < -1.0:
				_pass("client movement replicated to host (dz=%.2f)" % dz)
				# Do NOT quit yet: server teardown would despawn the
				# client's replicated nodes mid-test. Outlive the client.
				_phase = "wait_disconnect"
		"wait_disconnect":
			if root.multiplayer.get_peers().is_empty():
				_pass("client disconnected cleanly")
				return _finish()
	return false


func _finish() -> bool:
	print("HOST RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
