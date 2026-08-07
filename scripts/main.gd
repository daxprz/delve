extends Node3D
## Main scene controller (STO-CORE-003): host/join affordance and
## server-authoritative player spawning. One player node per peer,
## named by peer id; each peer has authority over its own player
## (see player.gd _enter_tree).

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlaygroundScript := preload("res://scripts/playground.gd")
const ProcMapScript := preload("res://scripts/procmap.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const MirrorScript := preload("res://scripts/mirror.gd")
const CharacterDB := preload("res://scripts/characters.gd")

## Where enemies start.
const ENEMY_SPAWNS: Array = [
	Vector3(7.0, 1.0, 6.0),
	Vector3(-7.0, 1.0, 5.0),
	Vector3(0.0, 1.0, -12.0),
]

@onready var players: Node3D = $Players
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var menu: CanvasLayer = $Menu

var _char_buttons: Array = []
var _in_game := false
var _pause_menu: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # so ESC works while paused
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_build_character_select()
	_build_pause_menu()
	$Menu/UI/VBox/HostButton.pressed.connect(host_game)
	$Menu/UI/VBox/JoinButton.pressed.connect(join_game)

	# Build the obstacle playground (EPI-WORLD-PLAYGROUND).
	var playground: Node3D = PlaygroundScript.new()
	playground.name = "Playground"
	add_child(playground)

	# A procedurally-generated maze map, in its OWN area away from the
	# playground/testing (STO-WORLD-004). Random layout each run.
	var procmap: Node3D = ProcMapScript.new()
	procmap.name = "ProcMap"
	procmap.set("map_seed", randi())  # different each play
	procmap.position = Vector3(22.0, 0.0, -15.0)
	add_child(procmap)

	# Spawn the follower enemies (EPI-ENEMIES-BASIC-ENEMY).
	_spawn_enemies()

	# A mirror near spawn so you can see your character (STO-CHARACTER-013).
	var mirror: Node3D = MirrorScript.new()
	mirror.name = "Mirror"
	mirror.position = Vector3(0.0, 0.0, -7.0)  # in front of the spawn (player faces -Z)
	add_child(mirror)

	# Launch-arg affordance for automation: godot -- --server | --client
	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--server"):
		host_game()
	elif user_args.has("--client"):
		join_game()


## Character-select screen (STO-CHARACTER-006): a row of buttons in the
## menu, one per character; clicking picks who you'll spawn as.
func _build_character_select() -> void:
	var vbox := $Menu/UI/VBox as VBoxContainer

	var label := Label.new()
	label.name = "ChooseLabel"
	label.text = "Choose your character:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	vbox.move_child(label, 0)

	var row := HBoxContainer.new()
	row.name = "CharRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)
	vbox.move_child(row, 1)

	for i in CharacterDB.count():
		var def := CharacterDB.get_def(i)
		var btn := Button.new()
		btn.name = "Char%d" % i
		btn.text = str(def["name"])
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(110, 40)
		btn.pressed.connect(_on_character_pressed.bind(i))
		row.add_child(btn)
		_char_buttons.append(btn)

	_update_character_buttons()


func _on_character_pressed(index: int) -> void:
	CharacterDB.selected_index = index
	_update_character_buttons()


func _update_character_buttons() -> void:
	for i in _char_buttons.size():
		var btn: Button = _char_buttons[i]
		btn.button_pressed = (i == CharacterDB.selected_index)


func _spawn_enemies() -> void:
	var root := Node3D.new()
	root.name = "Enemies"
	add_child(root)
	for i in ENEMY_SPAWNS.size():
		var enemy: CharacterBody3D = EnemyScript.new()
		enemy.name = "Enemy%d" % i
		enemy.position = ENEMY_SPAWNS[i]
		root.add_child(enemy)


## Pause menu (STO-CHARACTER-017): ESC pauses and shows Resume / Main Menu.
func _build_pause_menu() -> void:
	_pause_menu = CanvasLayer.new()
	_pause_menu.name = "PauseMenu"
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_menu.visible = false
	add_child(_pause_menu)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	_pause_menu.add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -110
	vbox.offset_top = -90
	vbox.offset_right = 110
	vbox.offset_bottom = 90
	vbox.add_theme_constant_override("separation", 16)
	dim.add_child(vbox)

	var label := Label.new()
	label.text = "Paused"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(200, 44)
	resume.pressed.connect(_toggle_pause)
	vbox.add_child(resume)

	var to_menu := Button.new()
	to_menu.name = "MainMenuButton"
	to_menu.text = "Main Menu"
	to_menu.custom_minimum_size = Vector2(200, 44)
	to_menu.pressed.connect(_to_main_menu)
	vbox.add_child(to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _in_game and event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	_pause_menu.visible = p
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED


func _to_main_menu() -> void:
	get_tree().paused = false
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()


func host_game() -> void:
	if Network.host() != OK:
		return
	menu.hide()
	_in_game = true
	_spawn_player(1)


func join_game() -> void:
	if Network.join() != OK:
		return
	menu.hide()
	_in_game = true


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var player := players.get_node_or_null(str(id))
		if player != null:
			player.queue_free()


func _spawn_player(id: int) -> void:
	DebugOverlay.log("network/spawn", self, "spawning player for peer %d", [id])
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = str(id)  # peer id doubles as node name -> authority
	player.position = spawn_point.position
	players.add_child(player)
