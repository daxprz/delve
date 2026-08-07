extends Node3D
## Main scene controller (STO-CORE-003): host/join affordance and
## server-authoritative player spawning. One player node per peer,
## named by peer id; each peer has authority over its own player
## (see player.gd _enter_tree).

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlaygroundScript := preload("res://scripts/playground.gd")
const ProcMapScript := preload("res://scripts/procmap.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const MirrorScript := preload("res://scripts/mirror.gd")
const CharacterDB := preload("res://scripts/characters.gd")

## Where enemies start.
const ENEMY_SPAWNS: Array = [
	Vector3(7.0, 1.0, 6.0),
	Vector3(-7.0, 1.0, 5.0),
	Vector3(0.0, 1.0, -12.0),
]

## Players arrive spread around a ring rather than stacked on one
## point (STO-CORE-004). 1.6 m is comfortably wider than the 0.8 m
## capsule diameter.
const SPAWN_RING_RADIUS := 1.6
const SPAWN_RING_SLOTS := 6

@onready var players: Node3D = $Players
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var menu: CanvasLayer = $Menu

var _char_buttons: Array = []
var _in_game := false
var _pause_menu: CanvasLayer
var _address_edit: LineEdit
var _map_seed := 0
var _server_list: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # so ESC works while paused
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_build_character_select()
	_build_pause_menu()
	# bind(true): a button click guarantees the pointer is inside the
	# window, so capturing immediately is Wayland-safe (STO-UI-002).
	$Menu/UI/VBox/HostButton.pressed.connect(host_game.bind(true))
	$Menu/UI/VBox/JoinButton.pressed.connect(join_game.bind(true))
	_build_address_field()

	# Build the obstacle playground (EPI-WORLD-PLAYGROUND).
	var playground: Node3D = PlaygroundScript.new()
	playground.name = "Playground"
	add_child(playground)

	# A procedurally-generated maze map, in its OWN area away from the
	# playground/testing (STO-WORLD-004). Random layout each run.
	_build_procmap(randi())  # a different maze each play, until we join

	# Spawn the follower enemies (EPI-ENEMIES-BASIC-ENEMY).
	_spawn_enemies()

	# A mirror near spawn so you can see your character (STO-CHARACTER-013).
	var mirror: Node3D = MirrorScript.new()
	mirror.name = "Mirror"
	mirror.position = Vector3(0.0, 0.0, -7.0)  # in front of the spawn (player faces -Z)
	add_child(mirror)

	# Launch-arg affordance for automation and for shortcuts against a
	# downloaded build:  --server  |  --client [address]
	var user_args := OS.get_cmdline_user_args()
	if user_args.has("--server"):
		host_game()
	elif user_args.has("--client"):
		var idx := user_args.find("--client")
		if idx + 1 < user_args.size() and not user_args[idx + 1].begins_with("--"):
			_address_edit.text = user_args[idx + 1]
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


## Enemies belong to the SERVER (STO-CORE-005). They are instanced
## from a scene and added under the EnemySpawner's path, so the
## spawner replicates them to every peer — including anyone who joins
## later. Each enemy carries a MultiplayerSynchronizer for its
## position and rotation.
##
## They used to be built from a script in _ready on EVERY instance,
## which meant each machine had its own private set: only the server
## ran their AI, so a client's copies stood frozen somewhere else
## entirely. Nothing about them agreed.
func _spawn_enemies() -> void:
	var container := $Enemies
	for c in container.get_children():
		c.queue_free()
	for i in ENEMY_SPAWNS.size():
		var enemy: CharacterBody3D = ENEMY_SCENE.instantiate()
		enemy.name = "Enemy%d" % i
		enemy.position = ENEMY_SPAWNS[i]
		container.add_child(enemy, true)


## Drop anything we built locally before joining — the server's copies
## are about to arrive and we must not have doubles.
func _clear_local_world() -> void:
	for c in $Enemies.get_children():
		c.queue_free()


## Build (or rebuild) the procedural maze from a specific seed.
## The seed decides the whole layout, so everyone must use the SAME
## one — otherwise players walk through walls their friend can see
## (STO-CORE-006).
func _build_procmap(seed_value: int) -> void:
	_map_seed = seed_value
	var existing := get_node_or_null("ProcMap")
	if existing != null:
		existing.name = "ProcMapOld"   # freeing is deferred; free the name now
		existing.queue_free()
	var procmap: Node3D = ProcMapScript.new()
	procmap.name = "ProcMap"
	procmap.set("map_seed", seed_value)
	procmap.position = Vector3(22.0, 0.0, -15.0)
	add_child(procmap)


func map_seed() -> int:
	return _map_seed


## Sent by the server to each peer as it joins, so the client throws
## away the maze it generated on its own and builds the server's.
@rpc("authority", "call_remote", "reliable")
func _receive_map_seed(seed_value: int) -> void:
	if seed_value != _map_seed:
		_build_procmap(seed_value)


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
	_set_mouse_locked(not p)


func _to_main_menu() -> void:
	get_tree().paused = false
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()


## Whether the game currently wants the pointer locked (STO-UI-002).
## Kept separate from Input.mouse_mode because the headless
## DisplayServer doesn't support CAPTURED (tests read this instead).
var mouse_locked := false


func _set_mouse_locked(locked: bool) -> void:
	mouse_locked = locked
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if locked \
			else Input.MOUSE_MODE_VISIBLE


func host_game(capture_mouse := false) -> void:
	if Network.host() != OK:
		return
	menu.hide()
	_in_game = true
	if capture_mouse:
		_set_mouse_locked(true)
	_spawn_player(1)


## Address box under the Join button (STO-TOOLS-004). Without this a
## downloaded build could only ever connect to itself — the join was
## hardwired to 127.0.0.1.
func _build_address_field() -> void:
	var vbox := $Menu/UI/VBox as VBoxContainer
	_address_edit = LineEdit.new()
	_address_edit.name = "AddressEdit"
	_address_edit.text = Network.DEFAULT_ADDRESS
	_address_edit.placeholder_text = "address to join (e.g. 192.168.1.20)"
	_address_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_address_edit.custom_minimum_size = Vector2(0, 36)
	# Enter in the box joins, so you can type an address and go.
	_address_edit.text_submitted.connect(func(_t: String) -> void:
		join_game(true))
	vbox.add_child(_address_edit)
	vbox.move_child(_address_edit, vbox.get_child_count() - 1)

	_server_list = VBoxContainer.new()
	_server_list.name = "SavedServers"
	_server_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_server_list)
	refresh_server_list()


## Rebuild the saved-server buttons (STO-TOOLS-006). Clicking one fills
## the address box and joins straight away; the small x forgets it.
func refresh_server_list() -> void:
	if _server_list == null:
		return
	for c in _server_list.get_children():
		c.queue_free()
	var saved: Array = Network.servers()
	if saved.is_empty():
		return
	var label := Label.new()
	label.text = "Places you've played:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_server_list.add_child(label)
	for entry in saved:
		var addr := String(entry["address"])
		var row := HBoxContainer.new()
		var go := Button.new()
		go.text = addr if String(entry.get("name", "")) == "" \
				else "%s  (%s)" % [String(entry["name"]), addr]
		go.custom_minimum_size = Vector2(170, 30)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.pressed.connect(func() -> void:
			_address_edit.text = addr
			join_game(true))
		row.add_child(go)
		var forget := Button.new()
		forget.text = "x"
		forget.tooltip_text = "Forget %s" % addr
		forget.custom_minimum_size = Vector2(30, 30)
		forget.pressed.connect(func() -> void:
			Network.forget_server(addr)
			refresh_server_list())
		row.add_child(forget)
		_server_list.add_child(row)


## Whatever address is typed in the box (falls back to the default).
func join_address() -> String:
	if _address_edit == null:
		return Network.DEFAULT_ADDRESS
	var t := _address_edit.text.strip_edges()
	return t if t != "" else Network.DEFAULT_ADDRESS


func join_game(capture_mouse := false) -> void:
	var addr := join_address()
	if Network.join(addr) != OK:
		return
	# Remember where we played so it's one click next time.
	Network.remember_server(addr)
	refresh_server_list()
	# The server owns the world: bin the enemies and maze we made on
	# our own, and wait for its versions (STO-CORE-005/006).
	_clear_local_world()
	menu.hide()
	_in_game = true
	if capture_mouse:
		_set_mouse_locked(true)


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		# Send our map seed first, so the joiner is standing in the
		# same maze before their player appears in it.
		_receive_map_seed.rpc_id(id, _map_seed)
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
	player.position = spawn_position_for_peer(id)
	players.add_child(player)


## Where a given peer appears (STO-CORE-004).
##
## Everyone used to spawn on the exact same marker, which was fine
## with one player and catastrophic with two: the capsules overlapped
## perfectly, and since a remote player's position is driven by the
## network sync it cannot be pushed aside — so each instance shoved
## its OWN player up to escape, synced the higher position, and shoved
## the other one higher again. Both players climbed forever (measured
## at 2.5 km and still accelerating).
##
## Derived from the PEER ID rather than a spawn counter, because each
## client has authority over its own player: whatever position the
## host picks is immediately overwritten by the client's own. Both
## sides computing the same answer from the id needs no messaging and
## cannot race.
func spawn_position_for_peer(id: int) -> Vector3:
	var base := spawn_point.position
	if id == 1:
		return base                      # the host takes the middle
	# A handful of fixed slots is not enough: peer ids are effectively
	# random, so two of them collide on the same slot far more often
	# than intuition suggests (4242 and 777 both landed on slot 2).
	# Spread continuously instead — angle AND distance both derived
	# from the id — so two peers landing on the same spot would take a
	# full hash collision.
	var h := absi(hash(id))
	var angle := float(h % 36000) / 36000.0 * TAU
	var radius := SPAWN_RING_RADIUS + float((h / 36000) % 100) / 100.0 * 1.4
	return base + Vector3(cos(angle), 0.0, sin(angle)) * radius
