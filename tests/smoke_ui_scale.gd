extends SceneTree
## Smoke test for STO-UI-003: a UI scale that sticks.
##   godot --headless -s res://tests/smoke_ui_scale.gd
## The menus were sized on a 1080p Linux screen and are unreadably
## small on a high-DPI Mac, so this has to be adjustable AND remembered
## — nobody wants to fix it on every launch.

var _failures := 0
var _ticks := 0
var _main: Node
var _settings: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_settings = root.get_node("/root/Settings")
		_check(_settings != null, "there is a Settings autoload")
		if _settings == null:
			return _finish()
		_settings.call("set_ui_scale", 1.0)

		# Stepping up and down walks the offered sizes.
		var up: float = _settings.call("step_ui_scale", 1)
		_check(up > 1.0, "stepping up enlarges the UI (%.2f)" % up)
		_settings.call("set_ui_scale", 3.0)
		_check(is_equal_approx(float(_settings.get("ui_scale")), 3.0),
				"3x is available for very small screens")
		_check(String(_settings.call("ui_scale_label")) == "3x",
				"it reads as '3x' (%s)" % String(_settings.call("ui_scale_label")))

		# It actually reaches the window, which is what scales the UI.
		_check(is_equal_approx(root.content_scale_factor, 3.0),
				"the window content scale follows (%.2f)"
				% root.content_scale_factor)

		# Out-of-range values are clamped, not obeyed.
		_settings.call("set_ui_scale", 99.0)
		_check(float(_settings.get("ui_scale")) <= 3.0,
				"absurd sizes are clamped (%.2f)" % float(_settings.get("ui_scale")))

		# THE POINT: survives a restart. Wipe memory, reload from disk.
		_settings.call("set_ui_scale", 2.0)
		_settings.set("ui_scale", 1.0)          # pretend a fresh launch
		_settings.call("load_settings")
		_check(is_equal_approx(float(_settings.get("ui_scale")), 2.0),
				"the choice survives a restart (%.2f loaded from disk)"
				% float(_settings.get("ui_scale")))

		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	# You can change it from the menu AND mid-game from the pause menu:
	# an unreadable UI is unreadable wherever you are.
	_check(_main.get_node_or_null("Menu/UI/VBox/UIScaleRow") != null,
			"the main menu offers it")
	var paused := _main.get_node_or_null("PauseMenu")
	var found_in_pause := false
	if paused != null:
		for n in paused.find_children("UIScaleRow", "", true, false):
			found_in_pause = true
	_check(found_in_pause, "the pause menu offers it too")

	_settings.call("set_ui_scale", 1.0)   # leave things as we found them
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
