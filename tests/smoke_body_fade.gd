extends SceneTree
## Headless smoke test for STO-CHARACTER-014 (own-body fade) and the
## STO-CHARACTER-013 fix (whole body shows in the mirror).
## Run with:  godot --headless -s res://tests/smoke_body_fade.gd
##
## The owner's body uses a distance-fade SHADER (fades by distance to the
## rendering camera). That means near parts fade for the owner's close
## camera, while the mirror's far camera renders the whole solid body.
## Verifies the owner's body carries that fade shader with fade params.

var _failures := 0
var _done_flag := false


func _physics_process(_delta: float) -> bool:
	if _done_flag:
		return true
	_done_flag = true
	_run()
	print("RESULT: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(1 if _failures > 0 else 0)
	return true


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.host_game()
	main.start_game()   # the lobby no longer starts the game for you
	var player := main.get_node_or_null("Players/1")
	if player == null:
		_fail("no player")
		return
	var body := player.get_node_or_null("Body")
	if body == null:
		_fail("no body")
		return

	if body.uses_fade_shader():
		_pass("owner's body uses the distance-fade shader")
	else:
		_fail("owner's body is not using the fade shader")

	# The shader material must carry the fade distances.
	var torso := body.find_child("Torso", true, false)
	var mesh: MeshInstance3D = null
	for c in torso.get_children():
		if c is MeshInstance3D:
			mesh = c
	if mesh == null:
		_fail("torso has no mesh")
		return
	var mat := mesh.material_override
	if mat is ShaderMaterial:
		var near = mat.get_shader_parameter("fade_near")
		var far = mat.get_shader_parameter("fade_far")
		if near != null and far != null and float(far) > float(near):
			_pass("fade shader has near=%.2f / far=%.2f (near parts fade, far parts solid)"
					% [float(near), float(far)])
		else:
			_fail("fade params missing/bad (near=%s far=%s)" % [near, far])
	else:
		_fail("torso material is not a ShaderMaterial")


func _pass(msg: String) -> void:
	print("PASS: %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("FAIL: %s" % msg)
