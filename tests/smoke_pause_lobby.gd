extends SceneTree
## Smoke tests for STO-UI-008 (change character while playing) and
## STO-UI-009 (drop back to the lobby without leaving the game).
##   godot --headless -s res://tests/smoke_pause_lobby.gd
##
## STO-UI-005 was marked SHIPPED claiming mid-game character switching
## existed. It did not — the picker was never added to the pause menu.
## So the check here is deliberately not "is there a row of buttons":
## it presses one and asks the PLAYER who it is afterwards.
##
## A button that exists and does nothing is exactly the failure this
## test is here to catch, because it is exactly the failure that
## happened.
##
## Runs offline. Neither feature needs a network, and needing port 7777
## would mean this could not run while the game is open.

const CHARS := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node
var _was := ""
var _row: Node


func _find(n: Node, nm: String) -> Node:
	if String(n.name) == nm:
		return n
	for c in n.get_children():
		var r := _find(c, nm)
		if r != null:
			return r
	return null


## The LIVE player, by exact name.
##
## Not "the first child that is not obviously dead". Switching
## character renames the old body to "1Old" and frees it next frame, so
## a loose filter hands back the body being thrown away — and the test
## then reports that switching character did nothing, when it had
## worked perfectly.
func _me() -> Node:
	var players := _main.get_node_or_null("Players")
	if players == null:
		return null
	return players.get_node_or_null("1")


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks == 1:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			if _ticks < 10:
				return false
			# Into a running game WITHOUT hosting.
			#
			# host_game() binds UDP 7777, and neither of these features
			# needs a network — so using it would have made this test
			# unrunnable whenever the operator has the game open, which
			# is most of the time. It goes straight to the state
			# start_game() produces instead.
			_main.call("_begin_game")
			_main.call("_spawn_player", 1)
			return false if _ticks < 30 else _next("in_game")

		"in_game":
			var me := _me()
			_check(me != null, "a player is in the world")
			if me == null:
				return _finish()
			_was = String(me.call("character_id"))
			print("[PAUSE] playing as %s" % _was)
			_next("find_row")

		"find_row":
			# The row that STO-UI-005 said existed and did not.
			_row = _find(_main, "PauseCharRow")
			_check(_row != null,
					"the pause menu HAS a character picker")
			_check(_find(_main, "LobbyButton") != null,
					"and a Back to Lobby button")
			_check(_find(_main, "MainMenuButton") != null,
					"with Main Menu still there, separately")
			if _row == null:
				return _finish()
			_next("switch")

		"switch":
			# Press a button for a DIFFERENT character.
			if _ticks == 1:
				var want := -1
				for i in int(CHARS.count()):
					if String(CHARS.get_def(i)["id"]) != _was:
						want = i
						break
				var buttons: Array = []
				for c in _row.get_children():
					if c is Button:
						buttons.append(c)
				print("[PAUSE] %d buttons in the pause picker; pressing #%d"
						% [buttons.size(), want])
				_check(buttons.size() == int(CHARS.count()),
						"one button per character (%d)" % buttons.size())
				if want < 0 or want >= buttons.size():
					_check(false, "there is another character to switch to")
					return _finish()
				(buttons[want] as Button).emit_signal("pressed")
				return false
			if _ticks < 20:
				return false
			var me := _me()
			_check(me != null, "there is still a player after switching")
			if me == null:
				return _finish()
			var now := String(me.call("character_id"))
			print("[PAUSE] now playing as %s (was %s)" % [now, _was])
			# THE check. Not "a button was pressed" — who am I now?
			_check(now != _was,
					"pressing it really CHANGES you: %s -> %s" % [_was, now])
			_next("lobby")

		"lobby":
			# Back to the lobby, still connected.
			if _ticks == 1:
				_check(not bool(_main.call("in_lobby")),
						"we are in the game, not the lobby")
				_main.call("_to_lobby")
				return false
			if _ticks < 20:
				return false
			_check(bool(_main.call("in_lobby")),
					"Back to Lobby puts us in the lobby")
			_check(not bool(_main.call("game_started")),
					"and the round has ended")
			# The whole point: it is NOT Main Menu.
			var peer = _main.get_tree().get_multiplayer().multiplayer_peer
			print("[PAUSE] multiplayer peer after going to lobby: %s"
					% ("still there" if peer != null else "GONE"))
			_check(peer != null,
					"but we are STILL CONNECTED — this is not Main Menu")
			_check(not _main.get_tree().paused,
					"and the game is not left paused")
			_next("no_ghosts")

		"no_ghosts":
			# Going back must not leave bodies standing about, or
			# starting again spawns a second one for everybody.
			var left := 0
			for c in _main.get_node("Players").get_children():
				if not String(c.name).ends_with("Gone"):
					left += 1
			print("[PAUSE] player bodies left in the world: %d" % left)
			_check(left == 0,
					"and no bodies are left standing in the world (%d)"
					% left)
			return _finish()
	return false


func _next(phase: String) -> bool:
	_phase = phase
	_ticks = 0
	return false


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
