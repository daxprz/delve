extends Node
## RCON (STO-TOOLS-001) — TCP remote console for driving a running
## delve instance from the shell:
##   echo "status" | nc -w2 localhost 9999
##
## Newline-delimited text commands, one response per line batch.
## Port falls back upward (9999, 10000, ...) when taken, so host and
## client instances on one machine can both listen.

const BASE_PORT := 9999
const PORT_TRIES := 5
const EnemyScript := preload("res://scripts/enemy.gd")

var port := 0  # actual bound port (0 = not listening)
var _server: TCPServer
var _clients: Array = []
var _fps_accum := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_server = TCPServer.new()
	for i in PORT_TRIES:
		var try_port := BASE_PORT + i
		if _server.listen(try_port) == OK:
			port = try_port
			print("RCON: listening on port %d" % port)
			return
	push_warning("RCON: no free port in %d..%d"
			% [BASE_PORT, BASE_PORT + PORT_TRIES - 1])


func _process(delta: float) -> void:
	if port == 0:
		return

	# perf/fps aspect: one line per second when enabled.
	_fps_accum += delta
	if _fps_accum >= 1.0:
		_fps_accum -= 1.0
		DebugOverlay.log("perf/fps", null, "fps=%d nodes=%d",
				[int(Engine.get_frames_per_second()),
				int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])

	if _server.is_connection_available():
		_clients.append(_server.take_connection())

	var doomed: Array = []
	for i in _clients.size():
		var peer: StreamPeerTCP = _clients[i]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			doomed.append(i)
			continue
		var available := peer.get_available_bytes()
		if available > 0:
			var text: String = peer.get_data(available)[1] \
					.get_string_from_utf8().strip_edges()
			for line in text.split("\n"):
				line = line.strip_edges()
				if line.is_empty():
					continue
				peer.put_data((_execute(line) + "\n").to_utf8_buffer())
	for i in range(doomed.size() - 1, -1, -1):
		_clients.remove_at(doomed[i])


## The live scene root. current_scene when the engine loaded it; in
## `-s` test runs (current_scene == null) fall back to the last child
## of root — autoloads come first, the test-added scene last.
func _scene_root() -> Node:
	var cs := get_tree().current_scene
	if cs != null:
		return cs
	var r := get_tree().root
	if r.get_child_count() > 0:
		var last := r.get_child(r.get_child_count() - 1)
		if last != self and last is not Window:
			return last
	return null


# -- Dispatch -----------------------------------------------------------

func _execute(command: String) -> String:
	var parts := command.split(" ", false)
	if parts.is_empty():
		return "ERR: empty command"
	match parts[0].to_lower():
		"help":
			return _cmd_help()
		"status":
			return _cmd_status()
		"fps":
			return "fps=%d" % int(Engine.get_frames_per_second())
		"rstat":
			return _cmd_rstat()
		"players":
			return _cmd_players()
		"enemies":
			return _cmd_enemies()
		"spawn":
			return _cmd_spawn(parts)
		"clear":
			return _cmd_clear()
		"tp":
			return _cmd_tp(parts)
		"debug":
			return _cmd_debug(parts)
		"eval":
			return _cmd_eval(command.substr(5))
		"quit":
			get_tree().quit()
			return "OK: quitting"
		_:
			return "ERR: unknown command '%s' (try help)" % parts[0]


func _cmd_help() -> String:
	return """Commands:
  help                       - this list
  status                     - port, scene, peers, players, enemies, fps
  fps                        - current FPS
  rstat                      - render/frame stats (draw calls, physics ms)
  players                    - list players: id, character, pos, hp
  enemies                    - list enemies: name, pos, hp
  spawn enemy [x y z]        - spawn an enemy (default near origin)
  clear                      - remove all enemies
  tp <player-id> <x> <y> <z> - teleport a player
  debug list                 - registered debug aspects + state
  debug on|off               - global VISUAL gate
  debug log <group/sub>      - textual output on for aspect
  debug vis <group/sub>      - visual output on for aspect
  debug none <group/sub>     - all output off for aspect
  debug clear                - remove test/script observers
  eval <expr>                - evaluate an expression (root = scene root)
  quit                       - quit the game"""


func _cmd_status() -> String:
	var tree := get_tree()
	var peers := "offline"
	if multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
		peers = "id=%d peers=%s" % [multiplayer.get_unique_id(),
				str(multiplayer.get_peers())]
	var scene := _scene_root()
	return "port=%d scene=%s net(%s) players=%d enemies=%d fps=%d" % [
		port,
		scene.name if scene else "none",
		peers,
		tree.get_nodes_in_group("players").size(),
		tree.get_nodes_in_group("enemies").size(),
		int(Engine.get_frames_per_second()),
	]


func _cmd_rstat() -> String:
	return "fps=%.0f draw=%d prims=%d proc=%.1fms phys=%.1fms nodes=%d" % [
		Engine.get_frames_per_second(),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	]


func _cmd_players() -> String:
	var lines: Array[String] = []
	for p in get_tree().get_nodes_in_group("players"):
		var char_id: String = p.character_id() if p.has_method("character_id") else "?"
		var hp: String = "%.0f/%.0f" % [p.health(), p.max_health()] \
				if p.has_method("health") else "?"
		lines.append("%s char=%s pos=(%.1f, %.1f, %.1f) hp=%s"
				% [p.name, char_id, p.global_position.x, p.global_position.y,
				p.global_position.z, hp])
	return "\n".join(lines) if not lines.is_empty() else "no players"


func _cmd_enemies() -> String:
	var lines: Array[String] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var hp: String = "%.0f" % e.health() if e.has_method("health") else "?"
		lines.append("%s pos=(%.1f, %.1f, %.1f) hp=%s"
				% [e.name, e.global_position.x, e.global_position.y,
				e.global_position.z, hp])
	return "\n".join(lines) if not lines.is_empty() else "no enemies"


func _cmd_spawn(parts: PackedStringArray) -> String:
	if parts.size() < 2 or parts[1] != "enemy":
		return "ERR: usage: spawn enemy [x y z]"
	var pos := Vector3(2.0, 1.5, 2.0)
	if parts.size() >= 5:
		pos = Vector3(parts[2].to_float(), parts[3].to_float(), parts[4].to_float())
	var scene := _scene_root()
	if scene == null:
		return "ERR: no live scene"
	var enemy: CharacterBody3D = EnemyScript.new()
	enemy.name = "RconEnemy%d" % (get_tree().get_nodes_in_group("enemies").size() + 1)
	enemy.position = pos
	scene.add_child(enemy)
	return "OK: spawned %s at (%.1f, %.1f, %.1f)" % [enemy.name, pos.x, pos.y, pos.z]


func _cmd_clear() -> String:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		e.queue_free()
	return "OK: removed %d enemies" % enemies.size()


func _cmd_tp(parts: PackedStringArray) -> String:
	if parts.size() < 5:
		return "ERR: usage: tp <player-id> <x> <y> <z>"
	for p in get_tree().get_nodes_in_group("players"):
		if p.name == parts[1]:
			p.global_position = Vector3(parts[2].to_float(),
					parts[3].to_float(), parts[4].to_float())
			return "OK: %s -> (%s, %s, %s)" % [p.name, parts[2], parts[3], parts[4]]
	return "ERR: no player named '%s' (try players)" % parts[1]


func _cmd_debug(parts: PackedStringArray) -> String:
	if parts.size() < 2:
		return "ERR: usage: debug list|on|off|log|vis|none|clear"
	match parts[1].to_lower():
		"list":
			return DebugOverlay.get_status_text()
		"on":
			DebugOverlay.global_enabled = true
			return "OK: global visual ON"
		"off":
			DebugOverlay.global_enabled = false
			return "OK: global visual OFF"
		"clear":
			DebugOverlay.clear_transient_observers()
			return "OK: transient observers cleared"
		"log", "vis", "none":
			if parts.size() < 3:
				return "ERR: usage: debug %s <group/sub>" % parts[1]
			var path := parts[2]
			if not DebugOverlay.has_aspect(path):
				return "ERR: unknown aspect '%s' (try debug list)" % path
			match parts[1].to_lower():
				"log":
					DebugOverlay.set_observer(path, "human", false,
							DebugOverlay.TextMode.LOG)
					return "OK: %s -> log" % path
				"vis":
					DebugOverlay.set_observer(path, "human", true,
							DebugOverlay.TextMode.NONE)
					return "OK: %s -> visual" % path
				_:
					DebugOverlay.set_observer(path, "human", false,
							DebugOverlay.TextMode.NONE)
					return "OK: %s -> off" % path
		_:
			return "ERR: unknown debug subcommand '%s'" % parts[1]


func _cmd_eval(expr_text: String) -> String:
	expr_text = expr_text.strip_edges()
	if expr_text.is_empty():
		return "ERR: usage: eval <expression>"
	var expr := Expression.new()
	if expr.parse(expr_text, ["root", "tree"]) != OK:
		return "ERR: parse: %s" % expr.get_error_text()
	var result: Variant = expr.execute([_scene_root(), get_tree()], self)
	if expr.has_execute_failed():
		return "ERR: exec: %s" % expr.get_error_text()
	return "OK: %s" % str(result)
