extends SceneTree
## Headless smoke test for STO-CHARACTER-013 (mirror).
## Run with:  godot --headless -s res://tests/smoke_mirror.gd
##
## Verifies the mirror exists with a reflection camera in a SubViewport
## and glass, and that the reflection camera tracks the player's camera
## (it moves to the reflected position rather than staying at the origin).

var _failures := 0
var _phase := "setup"
var _frames := 0
var _mirror: Node
var _cam: Camera3D
var _player: CharacterBody3D


func _setup() -> bool:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.host_game()
	_player = main.get_node_or_null("Players/1") as CharacterBody3D
	_mirror = main.get_node_or_null("Mirror")
	if _mirror == null:
		_fail("no Mirror in the scene")
		return false

	# Find the SubViewport + Camera3D + glass explicitly.
	var vp: SubViewport = null
	for c in _mirror.get_children():
		if c is SubViewport:
			vp = c
	if vp == null:
		_fail("mirror has no SubViewport")
		return false
	for c in vp.get_children():
		if c is Camera3D:
			_cam = c
	if _cam != null:
		_pass("mirror has a reflection camera in a SubViewport")
	else:
		_fail("mirror SubViewport has no Camera3D")
		return false

	var has_glass := false
	for c in _mirror.get_children():
		if c is MeshInstance3D:
			has_glass = true
	if has_glass:
		_pass("mirror has a glass/frame mesh")
	else:
		_fail("mirror has no visible surface")

	# Put the player in front of the mirror looking at it.
	if _player != null:
		_player.global_position = Vector3(0.0, 1.0, -3.0)
	return true


func _physics_process(_delta: float) -> bool:
	match _phase:
		"setup":
			if not _setup():
				return _done()
			_frames = 0
			_phase = "watch"
		"watch":
			_frames += 1
			if _frames >= 5:
				_check_tracking()
				return _done()
	return false


func _check_tracking() -> void:
	# After a few frames the reflection camera should have been moved to a
	# real reflected position (not left at the mirror's origin).
	var p := _cam.global_position
	var finite := is_finite(p.x) and is_finite(p.y) and is_finite(p.z)
	if finite and p.length() > 0.01:
		_pass("reflection camera tracks the viewer (at %s)" % str(p.round()))
	else:
		_fail("reflection camera did not update (%s)" % str(p))


func _done() -> bool:
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
