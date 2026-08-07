extends SceneTree
## Headless smoke test for STO-CHARACTER-017 (ESC pause menu).
## Run with:  godot --headless -s res://tests/smoke_pause.gd
##
## Verifies the pause menu exists with Resume + Main Menu buttons, and
## that toggling it pauses/unpauses the game and shows/hides the menu.

var _failures := 0
var _done_flag := false


func _physics_process(_delta: float) -> bool:
	if _done_flag:
		return true
	_done_flag = true
	_run()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.host_game()
	main.start_game()   # the lobby no longer starts the game for you

	var pm := main.get_node_or_null("PauseMenu")
	if pm == null:
		_fail("no PauseMenu")
		return
	var resume := main.find_child("ResumeButton", true, false)
	var to_menu := main.find_child("MainMenuButton", true, false)
	if resume != null and to_menu != null:
		_pass("pause menu has Resume + Main Menu buttons")
	else:
		_fail("pause menu missing buttons (resume=%s menu=%s)"
				% [resume != null, to_menu != null])

	# Toggle pause on.
	main.call("_toggle_pause")
	if paused and pm.visible:
		_pass("ESC pauses the game and shows the menu")
	else:
		_fail("pause did not take effect (paused=%s visible=%s)"
				% [paused, pm.visible])

	# Toggle pause off (Resume).
	main.call("_toggle_pause")
	if not paused and not pm.visible:
		_pass("Resume unpauses and hides the menu")
	else:
		_fail("resume did not unpause (paused=%s visible=%s)"
				% [paused, pm.visible])
	paused = false


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
