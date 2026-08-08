extends Node
## Version watermark in the top-right corner (STO-UI-007).
##
## delve gets handed round a network as downloaded builds, and everyone
## has to be on the same one — there is no protocol version check yet,
## so a mismatched client connects and then behaves strangely rather
## than refusing. Without this, the only way to know what someone is
## running is to ask them what they downloaded.
##
## An autoload with its own CanvasLayer rather than a node in
## main.tscn, so it is there on every screen — menu, lobby and in game
## — without three copies to keep in step.

## Above the menu and lobby layers so it is never hidden behind them.
const WATERMARK_LAYER := 128
const MARGIN := 8.0

var label: Label


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "VersionWatermark"
	canvas.layer = WATERMARK_LAYER
	# Follows the UI-size setting like everything else (STO-UI-003), so
	# it stays readable on a high-DPI screen.
	canvas.follow_viewport_enabled = false
	add_child(canvas)

	label = Label.new()
	label.name = "VersionLabel"
	label.text = version_string()
	# Pinned to the top-right: both anchors at 1.0 on x, 0.0 on y, and
	# the text grows leftward from the corner.
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.offset_left = -160.0
	label.offset_right = -MARGIN
	label.offset_top = MARGIN
	label.offset_bottom = MARGIN + 20.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Decoration, never a control: a watermark that swallowed clicks in
	# the corner of the menu would be a genuinely annoying bug.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	# A dark outline so it stays legible against both the bright
	# playground and the Sniper's pure-black screen.
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("outline_size", 3)
	canvas.add_child(label)


## "v0.1.10" — read from the project, never typed into the UI, so it
## cannot drift from what was actually built.
func version_string() -> String:
	return "v" + version()


func version() -> String:
	var v := String(ProjectSettings.get_setting("application/config/version", ""))
	return v if v != "" else "dev"
