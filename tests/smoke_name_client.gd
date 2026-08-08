extends SceneTree
## Player-name multiplayer test — CLIENT side (STO-UI-006).
## Run via scripts/run_mp_test.sh name (pairs with smoke_name_host.gd).
##
## Joins as "ClientClara" and checks that:
##   - the host's name ("HostHilda") arrives, not "Host" or a peer id
##   - our own name is in the list we were sent, i.e. the host really
##     broadcast it back rather than each machine knowing only itself
##   - a rename on the host reaches us without a restart

const MAX_TICKS := 900  # 15 s overall budget

var _main: Node
var _settings: Node
var _original_name := ""
var _ticks := 0
var _failures := 0
var _phase := "setup"
var _saw_first_name := false


func _physics_process(_delta: float) -> bool:
	if _phase == "setup":
		# Setup on first tick, not _initialize — autoloads join the
		# tree only after _initialize returns (godot-headless-testing).
		_settings = root.get_node("/root/Settings")
		_original_name = String(_settings.get("player_name"))
		# Set directly: must not overwrite the real saved name.
		_settings.set("player_name", "ClientClara")
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_main.join_game()
		print("CLIENT: joining 127.0.0.1 as ClientClara")
		_phase = "wait_host_name"
		return false

	_ticks += 1
	if _ticks > MAX_TICKS:
		_fail("timeout in phase '%s'" % _phase)
		return _finish()

	match _phase:
		"wait_host_name":
			var names: Dictionary = _main.call("lobby_names")
			var host_name := String(names.get(1, ""))
			var me := root.multiplayer.get_unique_id()
			# Wait for BOTH names, not just the host's.
			#
			# The host broadcasts the lobby the moment a peer connects,
			# which is BEFORE our _announce_name has crossed the wire —
			# so the first list we receive legitimately has the host's
			# name and an empty slot for us. Asserting on that first
			# sighting was a race: it passed whenever our announcement
			# happened to arrive first, and failed when it did not.
			if host_name == "HostHilda":
				if not _saw_first_name:
					_saw_first_name = true
					_pass("client sees the host's real name (%s)" % host_name)
					var shown := String(_main.call("lobby_display_name", 1))
					if shown == "HostHilda":
						_pass("and the lobby row shows it, not 'Host' (%s)" % shown)
					else:
						_fail("lobby row shows '%s', not the host's name" % shown)
				# The host must broadcast the whole list back, or we
				# would only ever know about ourselves.
				if String(names.get(me, "")) == "ClientClara":
					_pass("our own name came back in the host's broadcast")
					_phase = "wait_rename"
			elif host_name == "HostHenry":
				_fail("missed the first name — the rename arrived too early")
				_phase = "wait_rename"
		"wait_rename":
			var names2: Dictionary = _main.call("lobby_names")
			if String(names2.get(1, "")) == "HostHenry":
				if _saw_first_name:
					_pass("a rename on the host reaches us live (HostHenry)")
				return _finish()
	return false


func _finish() -> bool:
	if _settings != null:
		_settings.call("set_player_name", _original_name)  # leave no trace
	print("CLIENT RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
