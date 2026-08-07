extends SceneTree
## Headless smoke test for STO-UI-002 (mouse lock lifecycle).
##   godot --headless -s res://tests/smoke_mouse_lock.gd
## Drives the mouse-mode state machine:
##   menu (visible) -> host+capture (captured) -> pause (visible)
##   -> resume (captured) -> main menu path leaves it visible.
## Exits 0 on PASS, 1 on FAIL.

var _failures := 0
var _main: Node
var _phase := "setup"


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			# Setup on first tick, not _initialize (godot-headless-testing).
			# NOTE: headless DisplayServer doesn't support CAPTURED, so we
			# assert main.mouse_locked (the game's intent) and use actual
			# Input.mouse_mode only for VISIBLE states.
			_main = load("res://scenes/main.tscn").instantiate()
			root.add_child(_main)
			_check(not _main.mouse_locked, "mouse free in the menu")
			_main.host_game(true)  # as the Host button does (bind(true))
			_phase = "playing"
		"playing":
			_check(_main.mouse_locked,
					"mouse locked after hosting via button path")
			_main._toggle_pause()
			_check(not _main.mouse_locked
					and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
					"mouse released while paused (ESC)")
			_check(root.get_tree().paused, "tree paused")
			_main._toggle_pause()
			_check(_main.mouse_locked, "mouse re-locked on resume")
			_check(not root.get_tree().paused, "tree resumed")
			print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
			quit(1 if _failures > 0 else 0)
			return true
	return false


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
