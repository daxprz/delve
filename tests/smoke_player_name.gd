extends SceneTree
## Smoke test for STO-UI-006: a player name that sticks.
##   godot --headless -s res://tests/smoke_player_name.gd
##
## The lobby used to call people "Player 1477304918", which tells you
## nothing about who is actually there. A name is a property of the
## person, not of a session, so it is typed once and remembered.
##
## The multiplayer half of the story — that the OTHER machine sees
## your name — cannot be proven here with one instance. That lives in
## scripts/run_mp_test.sh.

var _failures := 0
var _ticks := 0
var _main: Node
var _settings: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_settings = root.get_node_or_null("/root/Settings")
		_check(_settings != null, "there is a Settings autoload")
		if _settings == null:
			return _finish()

		# --- cleaning up silly input ---------------------------------
		# A name box is a text field on someone else's screen; it will
		# receive whatever a person or a modified client can type.
		_settings.call("set_player_name", "Dax")
		_check(String(_settings.get("player_name")) == "Dax",
				"an ordinary name is kept as typed (%s)"
				% String(_settings.get("player_name")))

		_settings.call("set_player_name", "   Sam   ")
		_check(String(_settings.get("player_name")) == "Sam",
				"stray spaces are trimmed (%s)"
				% String(_settings.get("player_name")))

		_settings.call("set_player_name", "")
		_check(String(_settings.get("player_name")) == "",
				"an empty name is allowed (it means 'not set')")

		_settings.call("set_player_name", "        ")
		_check(String(_settings.get("player_name")) == "",
				"a name of only spaces counts as empty (%s)"
				% String(_settings.get("player_name")))

		var long_name := "A".repeat(200)
		_settings.call("set_player_name", long_name)
		var stored := String(_settings.get("player_name"))
		_check(stored.length() <= int(_settings.get("MAX_NAME_LENGTH")),
				"a very long name is cut down, not obeyed (%d chars)"
				% stored.length())

		_settings.call("set_player_name", "bad\nname\there")
		stored = String(_settings.get("player_name"))
		_check(not stored.contains("\n") and not stored.contains("\t"),
				"newlines and tabs are stripped so a row stays one line (%s)"
				% stored)

		# --- the stand-in when nobody set a name ---------------------
		# The whole point is that a peer id must NEVER reach the screen.
		var anon: String = _settings.call("display_name", "", 1477304918, 2)
		_check(anon != "" , "an unnamed player is never a blank row")
		_check(not anon.contains("1477304918"),
				"the stand-in is not the raw peer id (%s)" % anon)
		_check(String(_settings.call("display_name", "", 1, 1)) == "Host",
				"the unnamed host is called Host")
		_check(String(_settings.call("display_name", "Dax", 1, 1)) == "Dax",
				"a set name wins over the stand-in")

		# --- THE POINT: it survives a restart ------------------------
		# Proven the honest way (as in STO-UI-003): write it, wipe the
		# in-memory value, and reload from disk — the same path a fresh
		# launch takes.
		_settings.call("set_player_name", "Dax")
		_settings.set("player_name", "")          # pretend a fresh launch
		_settings.call("load_settings")
		_check(String(_settings.get("player_name")) == "Dax",
				"the name survives a restart (%s loaded from disk)"
				% String(_settings.get("player_name")))

		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	# --- a box to type it into, in both places -----------------------
	_check(_main.get_node_or_null("Menu/UI/VBox/NameRow/NameEdit") != null,
			"the main menu has a name box")
	var lobby := _main.get_node_or_null("Lobby")
	var lobby_edit: LineEdit = null
	if lobby != null:
		for n in lobby.find_children("NameEdit", "", true, false):
			lobby_edit = n
	_check(lobby_edit != null,
			"the lobby has one too, so a typo is fixable without quitting")

	# The box starts out showing the remembered name rather than blank.
	var menu_edit: LineEdit = _main.get_node("Menu/UI/VBox/NameRow/NameEdit")
	_check(menu_edit.text == "Dax",
			"the box opens showing the remembered name (%s)" % menu_edit.text)

	# --- the host's own name reaches the lobby list ------------------
	_main.call("host_game")
	var names: Dictionary = _main.call("lobby_names")
	_check(String(names.get(1, "")) == "Dax",
			"hosting puts your own name in the lobby list (%s)"
			% String(names.get(1, "")))
	_check(String(_main.call("lobby_display_name", 1)) == "Dax",
			"and that is what the lobby row shows (%s)"
			% String(_main.call("lobby_display_name", 1)))

	# Typing a new one updates the list without a restart.
	_main.call("_set_player_name", "Sam")
	_check(String(_main.call("lobby_display_name", 1)) == "Sam",
			"renaming yourself updates the lobby immediately (%s)"
			% String(_main.call("lobby_display_name", 1)))

	_settings.call("set_player_name", "")   # leave things as we found them
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)


func _finish() -> bool:
	print("RESULT: FAIL (%d)" % _failures)
	quit(1)
	return true
