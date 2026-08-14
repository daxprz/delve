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

## Where enemies start, and WHICH KIND each one is (STO-ENEMIES-017).
## Index into EnemyKinds.LIST: 0 = Walker, 1 = Crawler.
const ENEMY_SPAWNS: Array = [
	{"at": Vector3(7.0, 1.0, 6.0), "kind": 0},
	{"at": Vector3(-7.0, 1.0, 5.0), "kind": 0},
	{"at": Vector3(0.0, 1.0, -12.0), "kind": 0},
	{"at": Vector3(5.0, 1.0, -6.0), "kind": 1},
	{"at": Vector3(-5.0, 1.0, -9.0), "kind": 1},
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
## Lobby (STO-UI-004): everyone gathers, picks a character and can see
## who else is here before the host starts the game.
var _in_lobby := false
var _started := false
var _lobby_chars: Dictionary = {}     # peer id -> character index
var _lobby_names: Dictionary = {}     # peer id -> player name (STO-UI-006)
var _lobby_ui: CanvasLayer
var _lobby_list: VBoxContainer
var _start_button: Button
var _name_edits: Array = []           # every name box, kept in step


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # so ESC works while paused
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# The one moment a client KNOWS the host is listening. Announcing
	# from join_game() alone is a race: the RPC can be sent before the
	# connection exists and simply vanish (STO-UI-006).
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	_build_character_select()
	_build_pause_menu()
	# bind(true): a button click guarantees the pointer is inside the
	# window, so capturing immediately is Wayland-safe (STO-UI-002).
	$Menu/UI/VBox/HostButton.pressed.connect(host_game.bind(true))
	$Menu/UI/VBox/JoinButton.pressed.connect(join_game.bind(true))
	_build_name_field($Menu/UI/VBox, 0)   # first thing you see
	_build_address_field()
	_build_ui_scale_row($Menu/UI/VBox)
	_build_lobby()

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
		start_game()   # automation wants to play, not sit in a lobby
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

	var row := _build_character_row(vbox, "CharRow")
	vbox.move_child(row, 1)


func _update_character_buttons() -> void:
	# set_pressed_no_signal, NOT button_pressed: assigning the property
	# re-emits the button's signals, which called _choose_character
	# again and respawned the player on every refresh. With three
	# character rows now (menu, lobby, pause) that fired constantly.
	for i in _char_buttons.size():
		var btn: Button = _char_buttons[i]
		if is_instance_valid(btn):
			btn.set_pressed_no_signal(
					(i % CharacterDB.count()) == CharacterDB.selected_index)


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
		var spawn: Dictionary = ENEMY_SPAWNS[i]
		var enemy: CharacterBody3D = ENEMY_SCENE.instantiate()
		enemy.name = "Enemy%d" % i
		# Set BEFORE adding to the tree: the spawner replicates it with
		# the spawn, so every peer builds the same creature.
		enemy.set("kind", int(spawn["kind"]))
		enemy.position = spawn["at"]
		container.add_child(enemy, true)


## A "UI size: [-] 2x [+]" row (STO-UI-003). Added to both the main
## menu and the pause menu, because if the UI is too small to read you
## need to be able to fix it from wherever you are — including after
## you have already started playing.
## A "Your name:" box (STO-UI-006). Built into both the main menu and
## the lobby, so a typo can be fixed without leaving the game. Every
## box is registered in `_name_edits` and refreshed together, so the
## two never disagree about who you are.
func _build_name_field(parent: Control, at_index := -1) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "NameRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "Your name:"
	row.add_child(label)

	var edit := LineEdit.new()
	edit.name = "NameEdit"
	edit.text = Settings.player_name
	edit.placeholder_text = "who are you?"
	edit.max_length = Settings.MAX_NAME_LENGTH
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(220, 34)
	row.add_child(edit)
	_name_edits.append(edit)

	# Saved as you type: a name typed and then forgotten about is the
	# common case, and there is no OK button to press.
	edit.text_changed.connect(_set_player_name)
	edit.text_submitted.connect(func(t: String) -> void:
		_set_player_name(t)
		edit.release_focus())

	Settings.player_name_changed.connect(func(n: String) -> void:
		# Don't fight the box being typed into — only correct the others.
		if is_instance_valid(edit) and not edit.has_focus() and edit.text != n:
			edit.text = n)

	parent.add_child(row)
	if at_index >= 0:
		parent.move_child(row, at_index)
	return row


## Set our name and make sure everyone else learns it.
func _set_player_name(value: String) -> void:
	Settings.set_player_name(value)
	if multiplayer.multiplayer_peer == null \
			or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	var me := multiplayer.get_unique_id()
	_lobby_names[me] = Settings.player_name
	if multiplayer.is_server():
		_broadcast_lobby()
	else:
		_announce_name.rpc_id(1, Settings.player_name)


func _build_ui_scale_row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "UIScaleRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "UI size:"
	row.add_child(label)

	var smaller := Button.new()
	smaller.name = "Smaller"
	smaller.text = "−"
	smaller.custom_minimum_size = Vector2(40, 32)
	row.add_child(smaller)

	var value := Label.new()
	value.name = "Value"
	value.text = Settings.ui_scale_label()
	value.custom_minimum_size = Vector2(56, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value)

	var bigger := Button.new()
	bigger.name = "Bigger"
	bigger.text = "+"
	bigger.custom_minimum_size = Vector2(40, 32)
	row.add_child(bigger)

	smaller.pressed.connect(func() -> void: Settings.step_ui_scale(-1))
	bigger.pressed.connect(func() -> void: Settings.step_ui_scale(1))
	# Every row follows the setting, so the two menus never disagree.
	Settings.ui_scale_changed.connect(func(_s: float) -> void:
		if is_instance_valid(value):
			value.text = Settings.ui_scale_label())

	parent.add_child(row)
	return row


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

	# Fixing an unreadable UI must be possible mid-game too.
	_build_ui_scale_row(vbox)

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
	_lobby_chars = {1: CharacterDB.selected_index}
	_lobby_names = {1: Settings.player_name}
	_open_lobby(true)
	if capture_mouse:
		_set_mouse_locked(false)   # the lobby needs the cursor


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
	_open_lobby(false)
	if capture_mouse:
		_set_mouse_locked(false)   # the lobby needs the cursor
	# Who we are and what we picked is announced from
	# _on_connected_to_server, NOT here: at this point the peer is
	# still dialling, and an RPC sent now is thrown away with
	# "multiplayer peer which is not connected".


func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	# Send our map seed first, so the joiner is standing in the same
	# maze before their player appears in it.
	_receive_map_seed.rpc_id(id, _map_seed)
	if _started:
		# Joining a game already in progress: straight in. The joiner
		# must be TOLD the game is running, or it sits on its own lobby
		# screen forever while its player stands in the world.
		_lobby_chars[id] = _lobby_chars.get(id, 0)
		_begin_game.rpc_id(id)
		_spawn_player(id)
	else:
		if not _lobby_chars.has(id):
			_lobby_chars[id] = 0
		if not _lobby_names.has(id):
			_lobby_names[id] = ""   # until they tell us; shown as a stand-in
		_broadcast_lobby()


## A client has reached the host. This — not join_game() — is the
## moment it is safe to say who we are (STO-UI-006).
func _on_connected_to_server() -> void:
	_announce_name.rpc_id(1, Settings.player_name)
	_announce_character.rpc_id(1, CharacterDB.selected_index)


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var player := players.get_node_or_null(str(id))
		if player != null:
			player.queue_free()
		_lobby_chars.erase(id)
		_lobby_names.erase(id)
		_broadcast_lobby()


func _spawn_player(id: int) -> void:
	DebugOverlay.log("network/spawn", self, "spawning player for peer %d", [id])
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = str(id)  # peer id doubles as node name -> authority
	# The character choice travels WITH the spawn, so everyone sees
	# each other as what they actually picked. Previously only the
	# owner knew, and remote copies all appeared as the Grabber.
	player.character = int(_lobby_chars.get(id, CharacterDB.selected_index))
	player.position = spawn_position_for_peer(id)
	players.add_child(player, true)


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


# ---------------------------------------------------------------------
# Lobby (STO-UI-004 / STO-UI-005)
# ---------------------------------------------------------------------
#
# Host and Join used to drop you straight into the world, alone, with
# no idea whether anyone else had arrived. Now everyone gathers in a
# lobby first: you can see who is here, change character while you
# wait, and the host decides when to begin.
#
# Character choices are shared so the list is meaningful — and the
# choice now rides along when a player spawns, which also fixes remote
# players all appearing as the Grabber regardless of what they picked.

func _build_lobby() -> void:
	_lobby_ui = CanvasLayer.new()
	_lobby_ui.name = "Lobby"
	_lobby_ui.visible = false
	add_child(_lobby_ui)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.09, 0.92)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	_lobby_ui.add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -260
	vbox.offset_top = -220
	vbox.offset_right = 260
	vbox.offset_bottom = 220
	vbox.add_theme_constant_override("separation", 12)
	dim.add_child(vbox)

	var title := Label.new()
	title.text = "Lobby"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var who := Label.new()
	who.name = "Players"
	who.text = "Players:"
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(who)

	_lobby_list = VBoxContainer.new()
	_lobby_list.name = "PlayerList"
	_lobby_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_lobby_list)

	vbox.add_child(HSeparator.new())

	_build_name_field(vbox)

	var pick := Label.new()
	pick.text = "Your character:"
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pick)
	_build_character_row(vbox, "LobbyCharRow")

	_build_ui_scale_row(vbox)

	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.text = "Start game"
	_start_button.custom_minimum_size = Vector2(220, 46)
	_start_button.pressed.connect(start_game)
	vbox.add_child(_start_button)

	var leave := Button.new()
	leave.name = "LeaveButton"
	leave.text = "Leave"
	leave.custom_minimum_size = Vector2(220, 34)
	leave.pressed.connect(_to_main_menu)
	vbox.add_child(leave)


## A row of character buttons. Used by the main menu, the lobby and
## the pause menu, so switching character is possible from anywhere
## (STO-UI-005).
func _build_character_row(parent: Control, row_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = row_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in CharacterDB.count():
		var def := CharacterDB.get_def(i)
		var btn := Button.new()
		btn.name = "Char%d" % i
		btn.text = str(def["name"])
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(104, 38)
		btn.pressed.connect(_choose_character.bind(i))
		row.add_child(btn)
		_char_buttons.append(btn)
	parent.add_child(row)
	_update_character_buttons()
	return row


## Pick a character from anywhere. In the lobby this tells everyone
## else; in game it respawns you as the new one.
func _choose_character(index: int) -> void:
	if index == CharacterDB.selected_index and _started:
		return          # already playing as this one; nothing to do
	CharacterDB.selected_index = index
	_update_character_buttons()
	if multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
		var me := multiplayer.get_unique_id()
		_lobby_chars[me] = index
		if multiplayer.is_server():
			_broadcast_lobby()
		else:
			_announce_character.rpc_id(1, index)
	if _started:
		_respawn_as_selected()


## Swap the character you are playing without leaving the game
## (STO-UI-005): the old body goes, a new one arrives at your spawn.
func _respawn_as_selected() -> void:
	var me := 1
	if multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
		me = multiplayer.get_unique_id()
	if multiplayer.is_server():
		_replace_player(me, CharacterDB.selected_index)
	else:
		_request_respawn.rpc_id(1, CharacterDB.selected_index)


## Only the server may add or remove player nodes, so a client asks.
@rpc("any_peer", "call_remote", "reliable")
func _request_respawn(index: int) -> void:
	if not multiplayer.is_server():
		return
	_replace_player(multiplayer.get_remote_sender_id(), index)


func _replace_player(id: int, index: int) -> void:
	_lobby_chars[id] = index
	var old := players.get_node_or_null(str(id))
	if old != null:
		old.name = "%dOld" % id     # free the name now; freeing is deferred
		old.queue_free()
	_spawn_player(id)


func _open_lobby(is_host: bool) -> void:
	_in_lobby = true
	_started = false
	_in_game = false
	if _lobby_ui != null:
		_lobby_ui.visible = true
	if _start_button != null:
		_start_button.visible = is_host
		_start_button.disabled = not is_host
	_refresh_lobby()


## Host only: everyone into the world.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	_begin_game.rpc()
	_begin_game()
	for id in _lobby_chars.keys():
		if int(id) == 1 or multiplayer.get_peers().has(int(id)):
			_spawn_player(int(id))


@rpc("authority", "call_remote", "reliable")
func _begin_game() -> void:
	_in_lobby = false
	_started = true
	_in_game = true
	if _lobby_ui != null:
		_lobby_ui.visible = false
	_set_mouse_locked(true)


## A client telling the host which character it picked.
@rpc("any_peer", "call_remote", "reliable")
func _announce_character(index: int) -> void:
	if not multiplayer.is_server():
		return
	_lobby_chars[multiplayer.get_remote_sender_id()] = index
	_broadcast_lobby()


## A client telling the host what to call it (STO-UI-006).
@rpc("any_peer", "call_remote", "reliable")
func _announce_name(value: String) -> void:
	if not multiplayer.is_server():
		return
	# Cleaned again on arrival — see Settings.clean_name. Never trust
	# the machine at the other end to have behaved.
	_lobby_names[multiplayer.get_remote_sender_id()] = Settings.clean_name(value)
	_broadcast_lobby()


func _broadcast_lobby() -> void:
	if not multiplayer.is_server():
		return
	_sync_lobby.rpc(_lobby_chars, _lobby_names)
	_refresh_lobby()


@rpc("authority", "call_remote", "reliable")
func _sync_lobby(chars: Dictionary, names: Dictionary) -> void:
	_lobby_chars = chars.duplicate()
	_lobby_names = names.duplicate()
	_refresh_lobby()


func _refresh_lobby() -> void:
	if _lobby_list == null:
		return
	for c in _lobby_list.get_children():
		c.queue_free()
	var me := 1
	if multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer:
		me = multiplayer.get_unique_id()
	var ids := _lobby_chars.keys()
	ids.sort()
	for i in ids.size():
		var id: int = int(ids[i])
		var label := Label.new()
		# Their chosen name, or a readable stand-in — never a peer id
		# like 1477304918, and never a blank row (STO-UI-006).
		var who := Settings.display_name(
				str(_lobby_names.get(id, "")), id, i + 1)
		if id == me:
			who += " (you)"
		label.text = "%s — %s" % [who,
				str(CharacterDB.get_def(int(_lobby_chars[id]))["name"])]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lobby_list.add_child(label)


## Who is in the lobby and what they picked (for tests).
func lobby_players() -> Dictionary:
	return _lobby_chars


## Peer id -> name, as this machine currently understands it. Used by
## the two-instance test to prove each side sees the OTHER's name.
func lobby_names() -> Dictionary:
	return _lobby_names


## What this machine would print for a peer, stand-in included.
func lobby_display_name(peer_id: int) -> String:
	var ids := _lobby_chars.keys()
	ids.sort()
	var ordinal := ids.find(peer_id) + 1
	return Settings.display_name(str(_lobby_names.get(peer_id, "")),
			peer_id, maxi(ordinal, 1))


func in_lobby() -> bool:
	return _in_lobby


func game_started() -> bool:
	return _started
