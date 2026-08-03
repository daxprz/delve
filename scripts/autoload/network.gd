extends Node
## Network autoload (STO-CORE-003): ENet host/join over localhost.
## Registered as `Network` in project.godot.

const DEFAULT_PORT := 7777
const DEFAULT_ADDRESS := "127.0.0.1"


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
