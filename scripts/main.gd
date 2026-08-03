extends Node3D
## Main scene controller (STO-CORE-003): host/join affordance and
## server-authoritative player spawning. One player node per peer,
## named by peer id; each peer has authority over its own player
## (see player.gd _enter_tree).

const PLAYER_SCENE := preload("res://scenes/player.tscn")

@onready var players: Node3D = $Players
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var menu: CanvasLayer = $Menu


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	$Menu/UI/VBox/HostButton.pressed.connect(host_game)
	$Menu/UI/VBox/JoinButton.pressed.connect(join_game)

	# Launch-arg affordance for automation: godot -- --server | --client
	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--server"):
		host_game()
	elif user_args.has("--client"):
		join_game()


func host_game() -> void:
	if Network.host() != OK:
		return
	menu.hide()
	_spawn_player(1)


func join_game() -> void:
	if Network.join() != OK:
		return
	menu.hide()


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var player := players.get_node_or_null(str(id))
		if player != null:
			player.queue_free()


func _spawn_player(id: int) -> void:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = str(id)  # peer id doubles as node name -> authority
	player.position = spawn_point.position
	players.add_child(player)
