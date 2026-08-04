class_name Wings
extends Node3D
## The Flyer's procedural wings (STO-CHARACTER-022). Two wings, each a
## fan of feather segments off the shoulders, that flap. They flap faster
## when the player is climbing/flying. Same distance-fade shader as the
## body (fades near the owner's camera, solid in the mirror).

const GRAY := Color(0.55, 0.45, 0.68)
const FADE_NEAR := 0.6
const FADE_FAR := 1.2
const FEATHERS := 4

const FADE_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley;
uniform vec3 base_color : source_color = vec3(0.55, 0.45, 0.68);
uniform float fade_near = 0.6;
uniform float fade_far = 1.2;
varying vec3 v_world;
void vertex() { v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float d = distance(v_world, CAMERA_POSITION_WORLD);
	ALBEDO = base_color;
	ROUGHNESS = 0.7;
	ALPHA = clamp((d - fade_near) / (fade_far - fade_near), 0.0, 1.0);
}
"""

var _is_local := false
var _mat: Material
var _player
var _wing_roots: Array = []   # [L, R]
var _phase := 0.0


func _ready() -> void:
	_player = get_parent()
	_is_local = _player != null and _player.is_multiplayer_authority()
	_mat = _make_material()
	_build()
	set_process(true)
	print("[WINGS] built 2 wings")


func _make_material() -> Material:
	if _is_local:
		var sh := Shader.new()
		sh.code = FADE_SHADER
		var sm := ShaderMaterial.new()
		sm.shader = sh
		sm.set_shader_parameter("base_color", Vector3(GRAY.r, GRAY.g, GRAY.b))
		sm.set_shader_parameter("fade_near", FADE_NEAR)
		sm.set_shader_parameter("fade_far", FADE_FAR)
		return sm
	var m := StandardMaterial3D.new()
	m.albedo_color = GRAY
	m.roughness = 0.7
	return m


func _build() -> void:
	for side_v in [-1.0, 1.0]:
		var side := float(side_v)
		var root := Node3D.new()
		root.name = "Wing" + ("L" if side < 0.0 else "R")
		root.position = Vector3(0.28 * side, 1.45, 0.1)  # at the shoulders/back
		add_child(root)
		# A fan of feathers spreading out and back.
		for f in FEATHERS:
			var t := float(f) / float(FEATHERS - 1)
			var feather := MeshInstance3D.new()
			var box := BoxMesh.new()
			var length := lerpf(1.4, 0.9, t)
			box.size = Vector3(length, 0.06, 0.28)
			feather.mesh = box
			feather.material_override = _mat
			feather.position = Vector3(length * 0.5 * side, 0.0, 0.15 + t * 0.35)
			feather.rotation.y = deg_to_rad((-10.0 - t * 35.0) * side)
			root.add_child(feather)
		_wing_roots.append(root)


func _process(delta: float) -> void:
	# Flap faster when rising/flying; a slow idle flap otherwise.
	var rise := 0.0
	if _player != null:
		var v: Vector3 = _player.velocity
		rise = v.y
	var flap_rate := 3.0 + clampf(rise, 0.0, 8.0) * 1.5
	_phase += delta * flap_rate
	var flap := sin(_phase) * 0.6
	for k in _wing_roots.size():
		var side := -1.0 if k == 0 else 1.0
		var root: Node3D = _wing_roots[k]
		root.rotation.z = flap * side   # beat up and down


func wing_count() -> int:
	return _wing_roots.size()
