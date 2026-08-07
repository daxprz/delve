extends Node
## Player settings that outlive the game (STO-UI-003).
##
## Saved to user://settings.json, so they survive restarts — on Linux
## that is ~/.local/share/godot/app_userdata/Delve.
##
## Currently just the UI scale, which matters more than it sounds:
## delve's menus were sized on a 1080p Linux screen and are far too
## small to read on a high-DPI Mac display.

const SETTINGS_PATH := "user://settings.json"

## Sizes offered in the menus. 1.0 is the original look.
const UI_SCALES: Array = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
const DEFAULT_UI_SCALE := 1.0

signal ui_scale_changed(scale: float)

var ui_scale := DEFAULT_UI_SCALE


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


# --- persistence ------------------------------------------------------

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: could not save to %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({"ui_scale": ui_scale}, "\t"))
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
