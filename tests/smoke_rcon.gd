extends SceneTree
## Headless smoke test for STO-TOOLS-001 (RCON server).
##   godot --headless -s res://tests/smoke_rcon.gd
## Loads main.tscn, hosts, then talks to the Rcon autoload over REAL
## loopback TCP (StreamPeerTCP), exactly as `nc` would:
##   help, status, players, spawn enemy, enemies, clear, tp, eval,
##   debug list / debug log / bad input.
## Exits 0 on PASS, 1 on FAIL. Budgeted in physics ticks (60/s).

const MAX_TICKS := 600

var _ticks := 0
var _failures := 0
var _phase := "setup"
var _main: Node
var _sock: StreamPeerTCP
var _pending: Array = []   # queue of [command, check_fn, label]
var _reply_buf := ""
var _wait_ticks := 0


func _physics_process(_delta: float) -> bool:
	_ticks += 1
	if _ticks > MAX_TICKS:
		_fail("timeout in phase '%s'" % _phase)
		return _finish()

	match _phase:
		"setup":
			# Setup on first tick, not _initialize (godot-headless-testing).
			_main = load("res://scenes/main.tscn").instantiate()
			root.add_child(_main)
			_main.host_game()
			_phase = "connect"
		"connect":
			var rcon := root.get_node("/root/Rcon")
			if rcon.port == 0:
				_fail("Rcon is not listening")
				return _finish()
			_sock = StreamPeerTCP.new()
			if _sock.connect_to_host("127.0.0.1", rcon.port) != OK:
				_fail("could not open TCP connection to port %d" % rcon.port)
				return _finish()
			_queue_commands()
			_phase = "handshake"
		"handshake":
			_sock.poll()
			if _sock.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				_pass("TCP connected to RCON port")
				_send_next()
				_phase = "exchange"
			elif _sock.get_status() == StreamPeerTCP.STATUS_ERROR:
				_fail("TCP connection errored")
				return _finish()
		"exchange":
			_sock.poll()
			var available := _sock.get_available_bytes()
			if available > 0:
				_reply_buf += _sock.get_data(available)[1].get_string_from_utf8()
			# A reply is complete when we have at least one full line and
			# a couple of quiet ticks (multi-line replies arrive at once).
			_wait_ticks += 1
			if _reply_buf.contains("\n") and _wait_ticks > 3:
				var current: Dictionary = _pending.pop_front()
				_check(_reply_ok(current, _reply_buf.strip_edges()),
						current["label"], _reply_buf.strip_edges().left(120))
				_reply_buf = ""
				if _pending.is_empty():
					return _finish()
				_send_next()
	return false


## Each entry: { cmd, label, contains: [needles], prefix: "..." (opt),
## equals: "..." (opt) }. A reply passes when every given check holds.
func _queue_commands() -> void:
	_pending = [
		{"cmd": "help", "label": "help lists commands",
			"contains": ["status", "debug list"]},
		{"cmd": "status", "label": "status reports port/scene/players",
			"contains": ["port=", "players=1", "scene=Main"]},
		{"cmd": "players", "label": "players lists the hosted player",
			"contains": ["char=", "hp="]},
		{"cmd": "spawn enemy 3 1.5 3", "label": "spawn enemy works",
			"prefix": "OK: spawned"},
		{"cmd": "enemies", "label": "enemies lists the spawned enemy",
			"contains": ["RconEnemy", "hp="]},
		{"cmd": "tp 1 5 1 5", "label": "tp moves player 1",
			"prefix": "OK: 1 ->"},
		{"cmd": "eval root.get_node('Players').get_child_count()",
			"label": "eval runs expressions against the scene",
			"equals": "OK: 1"},
		{"cmd": "debug list", "label": "debug list shows aspect tree",
			"contains": ["enemy/", "network/"]},
		{"cmd": "debug log enemy/ai", "label": "debug log enables an aspect",
			"equals": "OK: enemy/ai -> log"},
		{"cmd": "debug log bogus/aspect", "label": "unknown aspect is rejected",
			"prefix": "ERR: unknown aspect"},
		{"cmd": "clear", "label": "clear removes enemies",
			"prefix": "OK: removed"},
		{"cmd": "nonsense", "label": "unknown command is rejected",
			"prefix": "ERR: unknown command"},
	]


func _reply_ok(spec: Dictionary, reply: String) -> bool:
	for needle in spec.get("contains", []):
		if not reply.contains(needle):
			return false
	if spec.has("prefix") and not reply.begins_with(spec["prefix"]):
		return false
	if spec.has("equals") and reply != spec["equals"]:
		return false
	return true


func _send_next() -> void:
	_wait_ticks = 0
	var cmd: String = _pending[0]["cmd"]
	_sock.put_data((cmd + "\n").to_utf8_buffer())


func _finish() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)


func _check(ok: bool, label: String, reply: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s (reply: %s)" % [label, reply])
