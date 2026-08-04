class_name Enemy
extends CharacterBody3D
## A dead-simple follower enemy (STO-ENEMIES-001): each physics tick it
## walks toward the nearest player. Gravity keeps it on the ground. When
## punched (or caught in a shockwave) it gets knocked back and briefly
## staggered, then resumes chasing. Server-authoritative.

const SPEED := 3.0
const FRICTION := 8.0
const STAGGER_TIME := 0.45   # seconds knocked back before chasing again
const MAX_HEALTH := 60.0     # how much damage it takes to defeat one
const FALL_SAFE_SPEED := 12.0  # landing faster than this hurts (dropped from height)
const FALL_DAMAGE_SCALE := 4.0

var _stagger := 0.0
var _mat: StandardMaterial3D
var _health := MAX_HEALTH
var _flash := 0.0
var _carried := false


func _ready() -> void:
	add_to_group("enemies")

	# Build a simple body from code (capsule + collision).
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	shape.shape = cap
	shape.position = Vector3(0.0, 0.8, 0.0)
	add_child(shape)

	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.6
	mesh.mesh = cm
	mesh.position = Vector3(0.0, 0.8, 0.0)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.8, 0.2, 0.2)
	_mat.roughness = 0.6
	mesh.material_override = _mat
	add_child(mesh)

	# Two little eyes so it has a "front".
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.08
		es.height = 0.16
		eye.mesh = es
		var em := StandardMaterial3D.new()
		em.albedo_color = Color(1, 1, 1)
		eye.material_override = em
		eye.position = Vector3(0.15 * sx, 1.25, -0.34)
		add_child(eye)


func _physics_process(delta: float) -> void:
	if _carried:
		return  # being carried by the Flyer — the player positions us

	if not multiplayer.is_server():
		return  # server drives the enemies

	if not is_on_floor():
		velocity += get_gravity() * delta

	var fall_speed := -velocity.y  # how fast we're dropping (before move)

	if _stagger > 0.0:
		# Knocked back — let it slide, don't steer.
		_stagger -= delta
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
	else:
		var target := _nearest_player()
		if target != null:
			var to := target.global_position - global_position
			to.y = 0.0
			if to.length() > 0.6:  # stop when basically on top of them
				var dir := to.normalized()
				velocity.x = dir.x * SPEED
				velocity.z = dir.z * SPEED
				look_at(global_position + dir, Vector3.UP)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	move_and_slide()
	# Enemies only chase — they do not deal damage.

	# Fall damage: landing hard (e.g. dropped from height) hurts.
	if is_on_floor() and fall_speed > FALL_SAFE_SPEED:
		take_damage((fall_speed - FALL_SAFE_SPEED) * FALL_DAMAGE_SCALE)


func _nearest_player() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for p in get_tree().get_nodes_in_group("players"):
		var node := p as Node3D
		if node == null:
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best


## Knock the enemy back (called by the punch / shockwave).
func apply_knockback(impulse: Vector3) -> void:
	velocity += impulse
	velocity.y = maxf(velocity.y, impulse.length() * 0.3)  # pop up a little
	_stagger = STAGGER_TIME


## Take damage; at 0 health the enemy is defeated (STO-ENEMIES-002).
func take_damage(amount: float) -> void:
	_health -= amount
	_flash = 0.12
	if _mat != null:
		_mat.albedo_color = Color(1, 1, 1)  # white flash
	if _health <= 0.0:
		queue_free()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and _mat != null:
			_mat.albedo_color = Color(0.8, 0.2, 0.2)


## Carried by the Flyer (STO-CHARACTER-024): freeze AI/gravity while held.
func set_carried(on: bool) -> void:
	_carried = on
	if on:
		velocity = Vector3.ZERO


func health() -> float:
	return _health


func max_health() -> float:
	return MAX_HEALTH
