extends SceneTree
## Smoke test for STO-TOOLS-004: you can type an address to join.
##   godot --headless -s res://tests/smoke_join_address.gd
## Before this the Join button was hardwired to 127.0.0.1, so a
## downloaded build could only ever connect to itself.

var _failures := 0
var _ticks := 0
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	var edit: LineEdit = _main.get_node_or_null("Menu/UI/VBox/AddressEdit")
	_check(edit != null, "the menu has an address box")
	if edit == null:
		return _finish()
	_check(edit.text == "127.0.0.1",
			"it defaults to localhost for same-machine play (%s)" % edit.text)
	_check(edit.placeholder_text.length() > 0,
			"it hints what to type")

	# Typing an address is what join uses.
	edit.text = "192.168.1.20"
	_check(_main.join_address() == "192.168.1.20",
			"join uses the typed address (%s)" % _main.join_address())

	# Blank falls back rather than failing to connect to "".
	edit.text = "   "
	_check(_main.join_address() == "127.0.0.1",
			"a blank box falls back to localhost (%s)" % _main.join_address())

	# Network.join must accept an address at all.
	var net := root.get_node("/root/Network")
	_check(net.has_method("join"), "Network.join exists")

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
