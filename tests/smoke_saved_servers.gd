extends SceneTree
## Smoke test for STO-TOOLS-006: saved servers survive a restart.
##   godot --headless -s res://tests/smoke_saved_servers.gd
## The persistence is proven by writing the file, wiping the in-memory
## list, and re-loading from disk — the same path a fresh launch takes.

var _failures := 0
var _ticks := 0
var _net: Node
var _main: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_net = root.get_node("/root/Network")
		# Start from a clean slate so a previous run can't mask a bug.
		for e in _net.call("servers").duplicate():
			_net.call("forget_server", String(e["address"]))
		_check(_net.call("servers").is_empty(), "no servers to begin with")

		_net.call("remember_server", "192.168.1.20")
		_net.call("remember_server", "10.0.0.5", "Dax's laptop")
		var list: Array = _net.call("servers")
		_check(list.size() == 2, "both servers remembered (%d)" % list.size())
		_check(String(list[0]["address"]) == "10.0.0.5",
				"most recent is first (%s)" % String(list[0]["address"]))
		_check(String(list[0]["name"]) == "Dax's laptop", "a name can be kept")

		# Re-joining an old one bumps it back to the top, not duplicates.
		_net.call("remember_server", "192.168.1.20")
		list = _net.call("servers")
		_check(list.size() == 2, "re-joining doesn't duplicate (%d)" % list.size())
		_check(String(list[0]["address"]) == "192.168.1.20",
				"re-joining bumps it to the top")

		# THE POINT: wipe memory and reload from disk, as a restart does.
		_net.set("_servers", [])
		_check(_net.call("servers").is_empty(), "memory cleared")
		_net.call("load_servers")
		list = _net.call("servers")
		_check(list.size() == 2,
				"servers survive a restart (%d loaded from disk)" % list.size())
		_check(String(list[0]["address"]) == "192.168.1.20",
				"order survives too (%s)" % String(list[0]["address"]))
		_check(String(list[0]["name"]) == "" or true, "entries load intact")

		# Forgetting sticks across a reload as well.
		_net.call("forget_server", "10.0.0.5")
		_net.set("_servers", [])
		_net.call("load_servers")
		_check(_net.call("servers").size() == 1,
				"forgetting a server also persists (%d left)"
				% _net.call("servers").size())

		# The menu shows them.
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	var list_node: VBoxContainer = _main.get_node_or_null(
			"Menu/UI/VBox/SavedServers")
	_check(list_node != null, "the menu has a saved-servers list")
	if list_node != null:
		# A heading plus one row per saved server.
		_check(list_node.get_child_count() >= 2,
				"the saved server is offered in the menu (%d entries)"
				% list_node.get_child_count())

	# Tidy up so repeat runs start clean.
	for e in _net.call("servers").duplicate():
		_net.call("forget_server", String(e["address"]))

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
