extends Node
## Network autoload (STO-CORE-003): ENet host/join over localhost.
## Registered as `Network` in project.godot.

const DEFAULT_PORT := 7777
const DEFAULT_ADDRESS := "127.0.0.1"

## Saved servers (STO-TOOLS-006). Written to user:// so they survive
## restarts — on Linux that is ~/.local/share/godot/app_userdata/Delve.
## Kept most-recent-first so the last place you played is the first
## thing you see.
const SERVERS_PATH := "user://servers.json"
const MAX_SERVERS := 8

var _servers: Array = []   # [{address, name, last_used}]


func _ready() -> void:
	load_servers()
	# network/peers debug aspect (STO-TOOLS-002).
	multiplayer.peer_connected.connect(func(id: int) -> void:
		DebugOverlay.log("network/peers", self, "peer %d connected", [id]))
	multiplayer.peer_disconnected.connect(func(id: int) -> void:
		DebugOverlay.log("network/peers", self, "peer %d disconnected", [id]))


func host(port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		push_error("Network.host: create_server(%d) failed: %s" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	print("Network: hosting on port %d (peer id %d)" % [port, multiplayer.get_unique_id()])
	return OK


func join(address := DEFAULT_ADDRESS, port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("Network.join: create_client(%s:%d) failed: %s"
				% [address, port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = peer
	print("Network: joining %s:%d" % [address, port])
	return OK


# --- Saved servers (STO-TOOLS-006) ------------------------------------
#
# A short address book that outlives the game. Joining a server
# remembers it, so next time you can click it instead of retyping an
# IP address — which matters a lot when the people you play with are
# on machines whose addresses you don't have memorised.

## Saved servers, most recently used first.
func servers() -> Array:
	return _servers


## Remember (or bump to the top) a server you just joined.
func remember_server(address: String, server_name := "") -> void:
	var addr := address.strip_edges()
	if addr == "":
		return
	for i in _servers.size():
		if String(_servers[i]["address"]) == addr:
			var existing: Dictionary = _servers[i]
			if server_name != "":
				existing["name"] = server_name
			existing["last_used"] = Time.get_unix_time_from_system()
			_servers.remove_at(i)
			_servers.push_front(existing)
			save_servers()
			return
	_servers.push_front({
		"address": addr,
		"name": server_name,
		"last_used": Time.get_unix_time_from_system(),
	})
	while _servers.size() > MAX_SERVERS:
		_servers.pop_back()
	save_servers()


func forget_server(address: String) -> void:
	for i in _servers.size():
		if String(_servers[i]["address"]) == address:
			_servers.remove_at(i)
			save_servers()
			return


func save_servers() -> void:
	var file := FileAccess.open(SERVERS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Network: could not save servers to %s" % SERVERS_PATH)
		return
	file.store_string(JSON.stringify({"servers": _servers}, "\t"))
	file.close()


func load_servers() -> void:
	_servers = []
	if not FileAccess.file_exists(SERVERS_PATH):
		return
	var file := FileAccess.open(SERVERS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("Network: servers file unreadable, starting fresh")
		return
	# Be forgiving about a hand-edited or older file.
	for entry in json.data.get("servers", []):
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("address"):
			continue
		_servers.append({
			"address": String(entry["address"]),
			"name": String(entry.get("name", "")),
			"last_used": float(entry.get("last_used", 0.0)),
		})
	while _servers.size() > MAX_SERVERS:
		_servers.pop_back()
