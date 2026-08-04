class_name Mirror
extends Node3D
## A planar mirror (STO-CHARACTER-013). A reflection camera renders the
## scene into a SubViewport, shown on a glass quad — so the player can
## walk up and see their whole body / arms / tail. The glass faces this
## node's +Z; place it facing the play area.

## Render layer for the mirror's own frame/glass, so the reflection
## camera doesn't render the mirror itself.
const FRAME_LAYER := 1 << 2

var _sub: SubViewport
var _cam: Camera3D
var _glass: MeshInstance3D


func _ready() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(480, 700)
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub)

	_cam = Camera3D.new()
	_cam.cull_mask = 0xFFFFF & ~FRAME_LAYER  # don't render the mirror frame
	add_child_to_viewport(_cam)

	# Frame
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(1.4, 1.9, 0.1)
	frame.mesh = fb
	frame.position = Vector3(0.0, 1.05, -0.06)
	frame.layers = FRAME_LAYER
	frame.material_override = _plain(Color(0.32, 0.23, 0.15))
	add_child(frame)

	# Glass showing the reflection
	_glass = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.25, 1.75)
	_glass.mesh = q
	_glass.position = Vector3(0.0, 1.05, 0.0)
	_glass.layers = FRAME_LAYER
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_texture = _sub.get_texture()
	gm.uv1_scale = Vector3(-1.0, 1.0, 1.0)  # flip horizontally -> mirror image
	_glass.material_override = gm
	add_child(_glass)

	print("[MIRROR] ready")


func add_child_to_viewport(node: Node) -> void:
	_sub.add_child(node)


func _plain(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


func _process(_delta: float) -> void:
	var viewer := get_viewport().get_camera_3d()
	if viewer == null or _cam == null:
		return
	# Reflect the viewer across the mirror plane (this node's +Z).
	var n := global_transform.basis.z.normalized()
	var o := _glass.global_position
	var vt := viewer.global_transform
	var refl_o := vt.origin - 2.0 * (vt.origin - o).dot(n) * n
	# Reflect the viewer's look + up, then build a valid basis via look_at.
	var fwd := _reflect(-vt.basis.z, n)
	var up := _reflect(vt.basis.y, n)
	_cam.global_position = refl_o
	if fwd.length() > 0.001:
		_cam.look_at(refl_o + fwd, up)
	_cam.fov = viewer.fov


func _reflect(v: Vector3, n: Vector3) -> Vector3:
	return v - 2.0 * v.dot(n) * n
