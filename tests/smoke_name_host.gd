extends SceneTree
## Player-name multiplayer test — HOST side (STO-UI-006).
## Run via scripts/run_mp_test.sh name (pairs with smoke_name_client.gd).
##
## The single-instance test can only prove a name is saved. It cannot
## prove the thing that actually matters: that the name reaches the
## OTHER machine. A name box that only works on your own screen would
## look perfectly fine in a solo test.
##
## Host is "HostHilda"; the client is "ClientClara". Each side has to
## see the other's name, and a rename mid-lobby has to travel too.

const MAX_TICKS := 900  # 15 s overall budget

var _main: Node
var _settings: Node
var _original_name := ""
var _ticks := 0
var _failures := 0
var _phase := "setup"
var _client_id := 0
var _wait := 0


func _physics_process(_delta: float) -> bool:
	if _phase == "setup":
		# Setup on first tick, not _initialize — autoloads join the
		# tree only after _initialize returns (godot-headless-testing).
		_settings = root.get_node("/root/Settings")
		_original_name = String(_settings.get("player_name"))
		# Set directly rather than via set_player_name: this must not
		# write over the real player's saved name mid-test.
		_settings.set("player_name", "HostHilda")
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_main.host_game()      # stay in the LOBBY — that is where names show
		print("HOST: hosting as HostHilda, waiting for client")
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
				_phase = "wait_name"
		"wait_name":
			var names: Dictionary = _main.call("lobby_names")
			var got := String(names.get(_client_id, ""))
			if got != "":
				if got == "ClientClara":
					_pass("host learned the client's name (%s)" % got)
				else:
					_fail("client's name arrived wrong: '%s'" % got)
				var shown := String(_main.call("lobby_display_name", _client_id))
				if shown == "ClientClara":
					_pass("and the lobby row shows it (%s)" % shown)
				else:
					_fail("lobby row shows '%s', not the name" % shown)
				if shown.contains(str(_client_id)):
					_fail("the raw peer id still leaked into the row")
				_wait = 0
				_phase = "rename"
		"rename":
			# Give the client time to observe "HostHilda" before we
			# change it, or it can never see the first name at all.
			_wait += 1
			if _wait > 60:
				_main.call("_set_player_name", "HostHenry")
				_pass("renamed self mid-lobby")
				_phase = "wait_disconnect"
		"wait_disconnect":
			if root.multiplayer.get_peers().is_empty():
				_pass("client disconnected cleanly")
				return _finish()
	return false


func _finish() -> bool:
	if _settings != null:
		_settings.call("set_player_name", _original_name)  # leave no trace
	print("HOST RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
