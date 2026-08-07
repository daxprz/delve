extends CanvasLayer
## In-game debug overlay panel (STO-TOOLS-003). Press F3 to toggle.
## Right-side panel: master visual gate, per-aspect Visual/Log
## checkboxes (human observer, persisted to the debug profile), and a
## live tail of recent DBG lines. Changes apply immediately.

const PANEL_WIDTH := 420.0
const LOG_LINES := 14
const REFRESH_SEC := 0.25

var _rows: Dictionary = {}  # aspect path -> [vis CheckBox, log CheckBox]
var _global_cb: CheckBox
var _log_label: Label
var _refresh := 0.0
var _syncing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F3:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	if visible:
		_sync_from_registry()
		_refresh_log()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		DebugOverlay.save_profile()
		# Back to play: re-capture if a local player is in the game.
		for p in get_tree().get_nodes_in_group("players"):
			if p.is_multiplayer_authority():
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				break


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh += delta
	if _refresh >= REFRESH_SEC:
		_refresh = 0.0
		_refresh_log()


# -- UI construction -----------------------------------------------------

func _build_ui() -> void:
	var root := PanelContainer.new()
	root.name = "Panel"
	root.anchor_left = 1.0
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = -PANEL_WIDTH
	root.self_modulate = Color(1, 1, 1, 0.92)
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	root.add_child(vbox)

	var title := Label.new()
	title.text = "Debug overlay  (F3)"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	_global_cb = CheckBox.new()
	_global_cb.text = "master VISUAL gate (gizmos draw only when on)"
	_global_cb.toggled.connect(func(on: bool) -> void:
		if not _syncing:
			DebugOverlay.global_enabled = on)
	vbox.add_child(_global_cb)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH - 20.0, 320.0)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var group := ""
	for path in DebugOverlay.get_aspect_paths():
		var parts: PackedStringArray = path.split("/", false, 2)
		if parts[0] != group:
			group = parts[0]
			var gl := Label.new()
			gl.text = group + "/"
			gl.add_theme_font_size_override("font_size", 15)
			gl.modulate = Color(0.7, 0.85, 1.0)
			list.add_child(gl)
		list.add_child(_build_row(path,
				parts[1] if parts.size() > 1 else path))

	vbox.add_child(HSeparator.new())

	var log_title := Label.new()
	log_title.text = "recent DBG lines"
	log_title.modulate = Color(0.7, 0.85, 1.0)
	vbox.add_child(log_title)

	_log_label = Label.new()
	_log_label.custom_minimum_size = Vector2(PANEL_WIDTH - 20.0, 220.0)
	_log_label.add_theme_font_size_override("font_size", 12)
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_log_label.clip_text = true
	vbox.add_child(_log_label)


func _build_row(path: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(190.0, 0.0)
	lbl.tooltip_text = path
	row.add_child(lbl)
	var vis_cb := CheckBox.new()
	vis_cb.text = "vis"
	row.add_child(vis_cb)
	var log_cb := CheckBox.new()
	log_cb.text = "log"
	row.add_child(log_cb)
	_rows[path] = [vis_cb, log_cb]
	var apply := func(_on: bool) -> void:
		if _syncing:
			return
		DebugOverlay.set_observer(path, "human", vis_cb.button_pressed,
				DebugOverlay.TextMode.LOG if log_cb.button_pressed
				else DebugOverlay.TextMode.NONE)
	vis_cb.toggled.connect(apply)
	log_cb.toggled.connect(apply)
	return row


# -- State sync ----------------------------------------------------------

func _sync_from_registry() -> void:
	_syncing = true
	_global_cb.button_pressed = DebugOverlay.global_enabled
	for path in _rows:
		var state: Array = DebugOverlay.get_observer_state(path, "human")
		(_rows[path][0] as CheckBox).button_pressed = state[0]
		(_rows[path][1] as CheckBox).button_pressed = \
				state[1] != DebugOverlay.TextMode.NONE
	_syncing = false


func _refresh_log() -> void:
	var hist: PackedStringArray = DebugOverlay.log_history
	var start := maxi(0, hist.size() - LOG_LINES)
	_log_label.text = "\n".join(hist.slice(start))
