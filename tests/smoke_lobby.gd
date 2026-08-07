extends SceneTree
## Smoke test for STO-UI-004 / STO-UI-005 — the lobby and character
## switching.
##   godot --headless -s res://tests/smoke_lobby.gd
##
## Hosting used to drop you straight into the world alone, with no way
## to tell whether anyone had arrived or to change your mind about a
## character. Now everyone gathers first and the host chooses when to
## begin.

const CharacterDB := preload("res://scripts/characters.gd")

var _failures := 0
var _ticks := 0
var _phase := "setup"
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	match _phase:
		"setup":
			if _ticks < 2:
				_main = load("res://scenes/main.tscn").instantiate()
				root.add_child(_main)
				return false
			CharacterDB.selected_index = 1        # Runner
			_main.host_game()
			_check(bool(_main.call("in_lobby")),
					"hosting opens the lobby instead of starting")
			_check(not bool(_main.call("game_started")),
					"the game has NOT started yet")
			_check(_main.get_node_or_null("Players").get_child_count() == 0,
					"nobody has spawned into the world yet")
			_check(_main.get_node_or_null("Lobby") != null,
					"there is a lobby screen")

			# You are listed, as the character you picked.
			var who: Dictionary = _main.call("lobby_players")
			_check(who.has(1), "the host appears in the lobby list")
			_check(int(who.get(1, -1)) == 1,
					"listed as the character picked (%s)"
					% str(who.get(1, -1)))

			# Changing your mind in the lobby is just a click.
			_main.call("_choose_character", 2)     # Flyer
			who = _main.call("lobby_players")
			_check(int(who.get(1, -1)) == 2,
					"changing character in the lobby updates the list")
			_check(not bool(_main.call("game_started")),
					"changing character does not start the game")

			# The mouse must be usable — it is a menu.
			_check(not bool(_main.get("mouse_locked")),
					"the cursor is free while in the lobby")
			_next("start")
		"start":
			if _ticks == 1:
				_main.call("start_game")
				_check(bool(_main.call("game_started")), "the host can start")
				_check(not bool(_main.call("in_lobby")), "the lobby closes")
				_check(bool(_main.get("mouse_locked")),
						"the mouse locks for play")
			if _ticks < 3:
				return false
			var players := _main.get_node("Players")
			_check(players.get_child_count() == 1,
					"the host spawned in (%d players)" % players.get_child_count())
			var p := players.get_child(0)
			_check(String(p.call("character_id")) == "flyer",
					"spawned as the character chosen in the lobby (%s)"
					% String(p.call("character_id")))
			_next("switch")
		"switch":
			if _ticks < 3:
				return false
			# STO-UI-005: switch character without leaving the game.
			if _ticks == 3:
				_main.call("_choose_character", 0)     # Grabber
				_next("switched")
		"switched":
			if _ticks < 5:
				return false
			var players := _main.get_node("Players")
			_check(players.get_child_count() == 1,
					"still exactly one player after switching (%d)"
					% players.get_child_count())
			var p := players.get_child(0)
			_check(String(p.call("character_id")) == "grabber",
					"respawned as the new character (%s)"
					% String(p.call("character_id")))
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
