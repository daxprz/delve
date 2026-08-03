class_name Player
extends CharacterBody3D
## First-person character controller (STO-CORE-002).
## WASD movement relative to facing, mouse look with captured cursor,
## jump + gravity. Esc toggles mouse capture.

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
const PITCH_LIMIT := deg_to_rad(89.0)

@onready var camera: Camera3D = $Camera3D

## Whether the player wants the mouse captured. We cannot capture in
## _ready() — on Wayland that errors until the pointer is actually
## over the window — so we capture lazily on the first mouse event.
var _capture_wanted := true


func _enter_tree() -> void:
	# Node name is the owning peer id (set by main.gd _spawn_player);
	# each peer has authority over its own player.
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	# Only the owning peer looks through this player's camera.
	camera.current = is_multiplayer_authority()


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			camera.rotation.x = clampf(camera.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
		elif _capture_wanted:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		_capture_wanted = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = (
			Input.MOUSE_MODE_CAPTURED if _capture_wanted
			else Input.MOUSE_MODE_VISIBLE
		)
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		_capture_wanted = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return  # remote copies follow the MultiplayerSynchronizer

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()
