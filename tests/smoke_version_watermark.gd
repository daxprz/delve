extends SceneTree
## Smoke test for STO-UI-007 — the version watermark.
##   godot --headless -s res://tests/smoke_version_watermark.gd
##
## delve is handed round a network as downloaded builds and everyone
## must be on the same one, so "which version am I running?" has to be
## answerable at a glance.

var _failures := 0
var _ticks := 0
var _main: Node
var _wm: Node


func _physics_process(_d: float) -> bool:
	_ticks += 1
	if _ticks == 1:
		_wm = root.get_node_or_null("/root/VersionWatermark")
		_check(_wm != null, "there is a VersionWatermark autoload")
		if _wm == null:
			return _finish()

		# The number must come from the project, not a string typed
		# into the UI — that is what stops it drifting from the build.
		var declared := String(ProjectSettings.get_setting(
				"application/config/version", ""))
		_check(declared != "",
				"the project declares a version (%s)" % declared)
		_check(String(_wm.call("version")) == declared,
				"the watermark reports the project's version (%s vs %s)"
				% [String(_wm.call("version")), declared])
		_check(String(_wm.call("version_string")) == "v" + declared,
				"it reads as v<version> (%s)"
				% String(_wm.call("version_string")))
		_check(not String(_wm.call("version")).begins_with("v"),
				"version() is the bare number, no doubled 'v'")

		var label: Label = _wm.get("label")
		_check(label != null, "it has a label")
		if label == null:
			return _finish()
		_check(label.text == "v" + declared,
				"the label shows it (%s)" % label.text)

		# TOP-RIGHT, which is the whole ask.
		_check(is_equal_approx(label.anchor_right, 1.0)
						and is_equal_approx(label.anchor_left, 1.0),
				"it is pinned to the RIGHT edge (anchors %.1f/%.1f)"
				% [label.anchor_left, label.anchor_right])
		_check(is_equal_approx(label.anchor_top, 0.0),
				"...and to the TOP edge (anchor %.1f)" % label.anchor_top)
		_check(label.offset_right <= 0.0,
				"it sits inside the right edge (offset %.1f)"
				% label.offset_right)
		_check(label.offset_top >= 0.0,
				"it sits below the top edge (offset %.1f)" % label.offset_top)

		# A watermark that swallowed clicks in the corner of the menu
		# would be a genuinely annoying bug.
		_check(label.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"it never blocks a click")

		var canvas := _wm.get_node_or_null("VersionWatermark") as CanvasLayer
		_check(canvas != null, "it lives on its own CanvasLayer")
		if canvas != null:
			_check(canvas.layer > 1,
					"...drawn above the menu and lobby (layer %d)" % canvas.layer)

		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		return false
	if _ticks < 4:
		return false

	# It is an autoload, so it survives the scene existing at all —
	# menu, lobby and in game alike, with no second copy to keep in step.
	var label2: Label = _wm.get("label")
	_check(is_instance_valid(label2),
			"it is still there once the game scene is loaded")
	var menu_layer := 0
	var menu := _main.get_node_or_null("Menu") as CanvasLayer
	if menu != null:
		menu_layer = menu.layer
	var canvas2 := _wm.get_node_or_null("VersionWatermark") as CanvasLayer
	_check(canvas2 != null and canvas2.layer > menu_layer,
			"it draws above the menu (watermark %d vs menu %d)"
			% [canvas2.layer if canvas2 != null else -1, menu_layer])

	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _finish() -> bool:
	print("RESULT: FAIL (%d)" % _failures)
	quit(1)
	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: %s" % label)
	else:
		_failures += 1
		print("FAIL: %s" % label)
