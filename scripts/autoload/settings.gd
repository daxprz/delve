extends Node
## Player settings that outlive the game (STO-UI-003).
##
## Saved to user://settings.json, so they survive restarts — on Linux
## that is ~/.local/share/godot/app_userdata/Delve.
##
## The UI scale matters more than it sounds: delve's menus were sized
## on a 1080p Linux screen and are far too small to read on a high-DPI
## Mac display.
##
## The player name (STO-UI-006) is here rather than in the lobby
## because it is a property of the person, not of a session: you type
## it once and every game afterwards already knows who you are.

const SETTINGS_PATH := "user://settings.json"

## Sizes offered in the menus. 1.0 is the original look.
const UI_SCALES: Array = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
const DEFAULT_UI_SCALE := 1.0

## Long enough for a real name, short enough that it cannot stretch a
## lobby row off the screen.
const MAX_NAME_LENGTH := 16

signal ui_scale_changed(scale: float)
signal player_name_changed(player_name: String)

var ui_scale := DEFAULT_UI_SCALE

## Empty means "never set one" — the lobby substitutes a readable
## stand-in rather than showing a blank row.
var player_name := ""


func _ready() -> void:
	load_settings()
	# Applied a frame late as well: on some platforms the window is not
	# ready to take a scale factor during autoload startup.
	apply_ui_scale()
	call_deferred("apply_ui_scale")


## Push the current scale into the window. Everything built from
## Control nodes scales with it; the 3D view is unaffected.
func apply_ui_scale() -> void:
	var w := get_window()
	if w != null:
		w.content_scale_factor = ui_scale


func set_ui_scale(value: float) -> void:
	var v := clampf(value, UI_SCALES[0], UI_SCALES[UI_SCALES.size() - 1])
	if is_equal_approx(v, ui_scale):
		return
	ui_scale = v
	apply_ui_scale()
	save_settings()
	ui_scale_changed.emit(ui_scale)


## Step to the next/previous offered size. Returns the new scale.
func step_ui_scale(direction: int) -> float:
	var idx := 0
	var best := INF
	for i in UI_SCALES.size():
		var d: float = absf(float(UI_SCALES[i]) - ui_scale)
		if d < best:
			best = d
			idx = i
	idx = clampi(idx + signi(direction), 0, UI_SCALES.size() - 1)
	set_ui_scale(UI_SCALES[idx])
	return ui_scale


## "2x" / "1.5x" — for buttons and labels.
func ui_scale_label() -> String:
	return ("%.2f" % ui_scale).rstrip("0").rstrip(".") + "x"


# --- Player name (STO-UI-006) -----------------------------------------

func set_player_name(value: String) -> void:
	var cleaned := clean_name(value)
	if cleaned == player_name:
		return
	player_name = cleaned
	save_settings()
	player_name_changed.emit(player_name)


## Make any string safe to show in a lobby row.
##
## Static, and applied on BOTH sides of the network: a name arrives
## over the wire from another machine, and a modified client could
## send a 10,000-character name or one full of newlines that would
## wreck everyone else's lobby. The receiver cleans it again rather
## than trusting the sender to have done it.
static func clean_name(value: String) -> String:
	var out := ""
	for i in value.length():
		# Drop control characters — newlines and tabs would break a
		# single-line Label into something unreadable.
		if value.unicode_at(i) >= 32:
			out += value[i]
	out = out.strip_edges()
	while out.contains("  "):
		out = out.replace("  ", " ")
	if out.length() > MAX_NAME_LENGTH:
		# strip_edges again: the cut can leave a trailing space behind.
		out = out.substr(0, MAX_NAME_LENGTH).strip_edges()
	return out


## What to call a peer that never set a name. `ordinal` is the peer's
## place in the lobby list, NOT its peer id — ids are values like
## 1477304918, which is precisely the unreadable thing this story
## exists to get rid of.
static func fallback_name(peer_id: int, ordinal: int) -> String:
	return "Host" if peer_id == 1 else "Player %d" % ordinal


## The name to actually show for a peer.
static func display_name(raw: String, peer_id: int, ordinal: int) -> String:
	var cleaned := clean_name(raw)
	return cleaned if cleaned != "" else fallback_name(peer_id, ordinal)


# --- persistence ------------------------------------------------------

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: could not save to %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"ui_scale": ui_scale,
		"player_name": player_name,
	}, "\t"))
	file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("Settings: file unreadable, using defaults")
		return
	# Be forgiving about a hand-edited file rather than losing settings.
	ui_scale = clampf(float(json.data.get("ui_scale", DEFAULT_UI_SCALE)),
			UI_SCALES[0], UI_SCALES[UI_SCALES.size() - 1])
	# Cleaned on the way in too: the file is editable by hand, and an
	# older file simply has no name key.
	player_name = clean_name(str(json.data.get("player_name", "")))
