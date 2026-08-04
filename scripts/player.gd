class_name Player
extends CharacterBody3D
## First-person character controller (STO-CORE-002).
## WASD movement relative to facing, mouse look with captured cursor,
## jump + gravity. Esc toggles mouse capture.

const MOUSE_SENSITIVITY := 0.002
const PITCH_LIMIT := deg_to_rad(89.0)
const MechanicalArmsScript := preload("res://scripts/mechanical_arms.gd")
const TailScript := preload("res://scripts/tail.gd")
const BodyScript := preload("res://scripts/body.gd")
const WingsScript := preload("res://scripts/wings.gd")
const ShockwaveScript := preload("res://scripts/shockwave.gd")
const CharacterDB := preload("res://scripts/characters.gd")
## Per-contact impulse used to push movable RigidBodies (scaled by speed).
const PUSH_IMPULSE := 0.12

@onready var camera: Camera3D = $Camera3D

## Which character this player is (index into CharacterDB.LIST). Applied
## in _ready. Defaults to 0 (Grabber).
var character := 0
# Stats filled in from the character def in _ready.
var _speed := 5.0
var _sprint_speed := 5.0
var _jump := 4.5
var _has_arms := true
var _double_jump := false
var _wall_jump := false
var _jumps_used := 0
# Health (STO-COMBAT-001).
var _max_health := 100.0
var _health := 100.0
var _hp_fill: ColorRect
var _spawn_pos := Vector3(0.0, 2.0, 0.0)
# Flyer (STO-CHARACTER-022/023/024).
const FLY_MAX_FUEL := 5.0      # seconds of flight
const FLY_ASCEND := 6.0        # up speed when flapping (jump held)
const FLY_H_SPEED := 6.0       # horizontal fly speed
const FLY_GLIDE_FALL := 2.0    # gentle sink when not flapping/diving
const FLY_DRAIN := 1.0         # fuel per second while flying
const FLY_RECHARGE := 4.0      # fuel per second on the ground
const DIVE_SPEED := 20.0       # dive-bomb down speed (Shift)
const DIVE_DRAIN := 2.0
const DIVE_IMPACT_POWER := 16.0  # shockwave power on a dive landing
const CARRY_RANGE := 3.0       # how close to grab an enemy (LMB+RMB)
var _can_fly := false
var _can_carry := false
var _fly_fuel := FLY_MAX_FUEL
var _fuel_fill: ColorRect
var _was_diving := false
var _carried_enemy: Node
var _force_carry := false
# Carried enemy dangles on a rope below the player (STO-CHARACTER-024).
const CARRY_ROPE := 1.5
const CARRY_DAMP := 0.92
var _carry_pos := Vector3.ZERO
var _carry_prev := Vector3.ZERO
# Combo system (STO-COMBAT-003): chained hits multiply damage.
const COMBO_WINDOW := 2.0       # seconds to land the next hit before it resets
const COMBO_STEP := 0.35        # +35% damage per combo level
const COMBO_AIR_BONUS := 1.5    # extra multiplier while airborne (flow!)
const COMBO_MAX := 10
var _combo := 0
var _combo_timer := 0.0
# --- Ability kit (EPI-CHARACTER-ABILITY-KIT) --------------------------
## Which abilities this character has (from the character def).
var _abilities: Array = []
# Heal-over-time for everyone (STO-CHARACTER-029): after a lull with no
# damage, slowly regenerate back to full.
const HEAL_RATE := 5.0          # hp per second
const HEAL_DELAY := 4.0         # seconds after a hit before regen starts
var _regen_timer := 0.0
# Grabber grapple-zip (STO-CHARACTER-025): instantly zip to the aimed point.
const ZIP_RANGE := 22.0
const ZIP_SPEED := 26.0
const ZIP_STOP := 1.6           # stop this close to the target
const ZIP_MAX_TIME := 1.2       # safety timeout
var _zipping := false
var _zip_target := Vector3.ZERO
var _zip_time := 0.0
# Grabber throw (STO-CHARACTER-026): grab a box/enemy and hurl it forward.
const THROW_GRAB_RANGE := 3.4
const THROW_FORCE := 22.0
const THROW_HOLD_DIST := 1.6    # how far in front the held object floats
var _held: Node
# Grabber pull (STO-CHARACTER-027): yank an enemy/box toward you.
const PULL_RANGE := 14.0
const PULL_FORCE := 16.0
# Grabber block/parry (STO-CHARACTER-028).
const BLOCK_REDUCE := 0.25      # take only 25% of damage while guarding
const PARRY_RANGE := 4.0
const PARRY_PUSH := 12.0
var _blocking := false
# Runner dodge roll (STO-CHARACTER-030): a fast, invincible roll.
const ROLL_SPEED := 13.0
const ROLL_TIME := 0.4
var _rolling := false
var _roll_time := 0.0
var _roll_dir := Vector3.ZERO
## Wall jump: launch away from the wall + up.
const WALL_JUMP_PUSH := 7.0
const WALL_JUMP_UP := 1.05
const WALL_JUMP_LOCK := 0.25   # seconds the launch carries before input takes over
var _wall_lock := 0.0

## Whether the player wants the mouse captured. We cannot capture in
## _ready() — on Wayland that errors until the pointer is actually
## over the window — so we capture lazily on the first mouse event.
var _capture_wanted := true

## Grapple rope (STO-CHARACTER-003). While a mechanical arm holds a solid
## grab, it sets the anchor + rope length (fixed when the grab began) and
## re-arms grapple_active each tick. The player then behaves like a
## pendulum on a rope: gravity + their own momentum swing them, and the
## rope only stops them going FURTHER than its length. Slow => they hang
## and dangle; fast => they swing (and can make it up onto a ledge).
var grapple_active := false
var grapple_anchor := Vector3.ZERO
var grapple_length := 0.0
## Gentle mid-swing steering, and a slight drag so weak swings settle.
const AIR_CONTROL := 10.0
const GRAPPLE_DRAG := 0.995


func _enter_tree() -> void:
	# Node name is the owning peer id (set by main.gd _spawn_player);
	# each peer has authority over its own player.
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	# Enemies look players up by group.
	add_to_group("players")

	# Only the owning peer looks through this player's camera.
	camera.current = is_multiplayer_authority()

	# The local (authoritative) player spawns as the selected character.
	if is_multiplayer_authority():
		character = CharacterDB.selected_index

	# Apply the character definition (STO-CHARACTER-004/005).
	var def := CharacterDB.get_def(character)
	_speed = def["speed"]
	_sprint_speed = def.get("sprint", _speed)
	_jump = def["jump"]
	_has_arms = def["arms"]
	_double_jump = def["double_jump"]
	_wall_jump = def.get("wall_jump", false)
	_max_health = def.get("health", 100.0)
	_health = _max_health
	_spawn_pos = global_position
	_can_fly = def.get("fly", false)
	_can_carry = def.get("carry", false)
	_abilities = def.get("abilities", [])
	if is_multiplayer_authority():
		_build_hud()

	# A jointed humanoid body (STO-CHARACTER-012), for every character. The
	# owner's body fades near their camera (STO-CHARACTER-014); the Grabber
	# gets no human arms — its mechanical arms attach instead.
	var body: Node3D = BodyScript.new()
	body.name = "Body"
	body.set("build_human_arms", not _has_arms)
	add_child(body)

	# Only the Grabber builds the mechanical arms (STO-CHARACTER-001).
	if _has_arms:
		var arms: Node3D = MechanicalArmsScript.new()
		arms.name = "MechanicalArms"
		add_child(arms)

	# The Runner has a long physics tail (STO-CHARACTER-010).
	if def.get("tail", false):
		var tail: Node3D = TailScript.new()
		tail.name = "Tail"
		add_child(tail)

	# The Flyer has wings (STO-CHARACTER-022).
	if def.get("wings", false):
		var wings: Node3D = WingsScript.new()
		wings.name = "Wings"
		add_child(wings)


## The character's stable id (for UI / tests).
func character_id() -> String:
	return CharacterDB.get_def(character)["id"]


## This character's walk speed (for tests).
func move_speed() -> float:
	return _speed


func sprint_speed() -> float:
	return _sprint_speed


func has_wall_jump() -> bool:
	return _wall_jump


func has_double_jump() -> bool:
	return _double_jump


# --- Health (STO-COMBAT-001 / 002) --------------------------------------

func health() -> float:
	return _health

func max_health() -> float:
	return _max_health


## Take damage; dropping to 0 respawns the player at full health.
func take_damage(amount: float) -> void:
	if _rolling:
		return  # invincible during a dodge roll (STO-CHARACTER-030)
	if _blocking:
		amount *= BLOCK_REDUCE  # guarding softens the blow (STO-CHARACTER-028)
	_health = maxf(0.0, _health - amount)
	_regen_timer = HEAL_DELAY  # pause heal-over-time after a hit
	_combo = 0  # getting hit breaks your combo
	if _health <= 0.0:
		_respawn()


func is_blocking() -> bool:
	return _blocking

func is_rolling() -> bool:
	return _rolling


## Deal `amount` damage to `target`, scaled by the current combo (and an
## air-chain bonus). Builds the combo. All the player's attacks route
## through here (STO-COMBAT-003).
func deal_damage(target, amount: float) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	_combo_timer = COMBO_WINDOW
	var mult := 1.0 + mini(_combo, COMBO_MAX) * COMBO_STEP
	if not is_on_floor():
		mult *= COMBO_AIR_BONUS
	target.call("take_damage", amount * mult)
	_combo += 1


func combo() -> int:
	return _combo


func _respawn() -> void:
	_health = _max_health
	velocity = Vector3.ZERO
	global_position = _spawn_pos


## A simple health bar in the corner for the owning player.
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.size = Vector2(224, 28)
	bg.anchor_top = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 20
	bg.offset_top = -52
	bg.offset_right = 244
	bg.offset_bottom = -24
	hud.add_child(bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.85, 0.2, 0.2)
	_hp_fill.position = Vector2(2, 2)
	_hp_fill.size = Vector2(220, 24)
	bg.add_child(_hp_fill)

	# Flyer: a blue flight-fuel bar above the health bar.
	if _can_fly:
		var fbg := ColorRect.new()
		fbg.color = Color(0, 0, 0, 0.55)
		fbg.size = Vector2(224, 20)
		fbg.anchor_top = 1.0
		fbg.anchor_bottom = 1.0
		fbg.offset_left = 20
		fbg.offset_top = -78
		fbg.offset_right = 244
		fbg.offset_bottom = -58
		hud.add_child(fbg)
		_fuel_fill = ColorRect.new()
		_fuel_fill.color = Color(0.3, 0.6, 0.95)
		_fuel_fill.position = Vector2(2, 2)
		_fuel_fill.size = Vector2(220, 16)
		fbg.add_child(_fuel_fill)


func _process(_delta: float) -> void:
	if _hp_fill != null and _max_health > 0.0:
		_hp_fill.size.x = 220.0 * (_health / _max_health)
	if _fuel_fill != null:
		_fuel_fill.size.x = 220.0 * clampf(_fly_fuel / FLY_MAX_FUEL, 0.0, 1.0)


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
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		_capture_wanted = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return  # remote copies follow the MultiplayerSynchronizer

	var grappling := grapple_active
	grapple_active = false  # arms re-arm each tick while the grab is held

	# Combo decays if you don't land a hit in time (STO-COMBAT-003).
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0

	# Passive heal-over-time for everyone (STO-CHARACTER-029).
	_update_heal(delta)

	# Ability inputs: Grabber kit (zip/throw/pull/block) + Runner dodge.
	_update_abilities()

	# Grapple-zip and dodge-roll take over movement while they last.
	if _zipping:
		_zip_move(delta)
		move_and_slide()
		return
	if _rolling:
		_roll_move(delta)
		move_and_slide()
		return

	# Flyer: carry a grabbed enemy, and fly while airborne (STO-CHARACTER-022+).
	if _can_carry:
		_update_carry()
	if _can_fly:
		if is_on_floor():
			if _was_diving:
				_dive_impact()
				_was_diving = false
			_fly_fuel = minf(FLY_MAX_FUEL, _fly_fuel + FLY_RECHARGE * delta)
		else:
			_fly_move(delta)
			move_and_slide()
			return

	if is_on_floor():
		_jumps_used = 0
	else:
		velocity += get_gravity() * delta

	# Jump — from the floor, off a wall (wall-jump characters), or a mid-air
	# double jump (double-jump characters).
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = _jump
			_jumps_used = 1
		elif _wall_jump and is_on_wall():
			var n := get_wall_normal()   # points away from the wall
			velocity.x = n.x * WALL_JUMP_PUSH
			velocity.z = n.z * WALL_JUMP_PUSH
			velocity.y = _jump * WALL_JUMP_UP
			_wall_lock = WALL_JUMP_LOCK  # keep the launch through input override
		elif _double_jump and _jumps_used < 2:
			velocity.y = _jump
			_jumps_used += 1

	# Hold Shift to sprint (fast); otherwise walk.
	var spd := _sprint_speed if Input.is_action_pressed("sprint") else _speed
	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if _wall_lock > 0.0:
		_wall_lock -= delta

	if grappling or _wall_lock > 0.0:
		# Keep momentum (grapple swing / wall-jump launch): only gentle steer.
		if direction:
			velocity += direction * AIR_CONTROL * delta
	else:
		if direction:
			velocity.x = direction.x * spd
			velocity.z = direction.z * spd
		else:
			velocity.x = move_toward(velocity.x, 0.0, _speed)
			velocity.z = move_toward(velocity.z, 0.0, _speed)

	move_and_slide()

	if grappling:
		_apply_rope()

	_push_rigid_bodies()


# --- Flyer (STO-CHARACTER-022/023/024) --------------------------------

func fly_fuel() -> float:
	return _fly_fuel

func carried_enemy() -> Node:
	return _carried_enemy


## Airborne flight: full horizontal control; jump = flap up, Shift = dive
## bomb, otherwise glide down slowly. Flying drains fuel; at 0 fuel you fall.
func _fly_move(delta: float) -> void:
	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if _fly_fuel > 0.0:
		velocity.x = direction.x * FLY_H_SPEED
		velocity.z = direction.z * FLY_H_SPEED
		if Input.is_action_pressed("sprint"):        # Shift = dive bomb
			velocity.y = -DIVE_SPEED
			_was_diving = true
			_fly_fuel -= DIVE_DRAIN * delta
		elif Input.is_action_pressed("jump"):        # flap up
			velocity.y = FLY_ASCEND
			_was_diving = false
			_fly_fuel -= FLY_DRAIN * delta
		else:                                         # glide
			velocity.y = -FLY_GLIDE_FALL
			_was_diving = false
			_fly_fuel -= FLY_DRAIN * 0.5 * delta
		_fly_fuel = maxf(0.0, _fly_fuel)
	else:
		# Out of fuel: normal gravity, some air control.
		velocity += get_gravity() * delta
		if direction:
			velocity.x = direction.x * _speed
			velocity.z = direction.z * _speed


## Landing from a dive: a shockwave that damages nearby enemies.
func _dive_impact() -> void:
	var sw: Node3D = ShockwaveScript.new()
	sw.set("power", DIVE_IMPACT_POWER)
	sw.set("source", self)
	var host: Node = get_parent()
	if host == null:
		host = self
	sw.position = global_position
	host.add_child(sw)


## While LMB+RMB are both held, carry the nearest enemy in the Flyer's
## talons; release to drop it (it falls and takes fall damage).
func _update_carry() -> void:
	var mouse := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	_do_carry(mouse or _force_carry)


## Test/scripting hooks.
func set_fuel(f: float) -> void:
	_fly_fuel = f

func test_carry(on: bool) -> void:
	_force_carry = on
	_do_carry(on)


func _do_carry(grabbing: bool) -> void:
	if grabbing:
		if _carried_enemy == null or not is_instance_valid(_carried_enemy):
			_carried_enemy = _nearest_enemy(CARRY_RANGE)
			if _carried_enemy != null and _carried_enemy.has_method("set_carried"):
				_carried_enemy.call("set_carried", true)
				_carry_pos = (_carried_enemy as Node3D).global_position
				_carry_prev = _carry_pos
		if _carried_enemy != null and is_instance_valid(_carried_enemy):
			# The enemy DANGLES on a rope below the player: a little verlet
			# swing that reacts to the player's movement.
			var anchor := global_position + Vector3(0.0, -0.4, 0.0)
			var dt := get_physics_process_delta_time()
			var vel := (_carry_pos - _carry_prev) * CARRY_DAMP
			_carry_prev = _carry_pos
			_carry_pos = _carry_pos + vel + Vector3(0.0, -18.0, 0.0) * dt * dt
			var to := _carry_pos - anchor
			var dist := to.length()
			if dist > CARRY_ROPE and dist > 0.001:
				_carry_pos = anchor + to / dist * CARRY_ROPE
			(_carried_enemy as Node3D).global_position = _carry_pos
	else:
		if _carried_enemy != null and is_instance_valid(_carried_enemy) \
				and _carried_enemy.has_method("set_carried"):
			_carried_enemy.call("set_carried", false)  # drop it
		_carried_enemy = null


# --- Ability kit (EPI-CHARACTER-ABILITY-KIT) --------------------------

func _has_ability(name: String) -> bool:
	return _abilities.has(name)


## Slowly regenerate health once you've been out of danger for a moment.
func _update_heal(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if _health < _max_health:
		_health = minf(_max_health, _health + HEAL_RATE * delta)


## Read ability keys each tick and trigger the ones this character has.
func _update_abilities() -> void:
	# Guard key (C): the Grabber blocks (held), the Runner dodge-rolls (tap).
	if _has_ability("block"):
		_blocking = Input.is_action_pressed("ability_guard")
		if Input.is_action_just_pressed("ability_guard"):
			do_parry()
	if _has_ability("dodge") and Input.is_action_just_pressed("ability_guard"):
		do_dodge()
	if _has_ability("zip") and Input.is_action_just_pressed("ability_zip"):
		do_zip()
	if _has_ability("throw") and Input.is_action_just_pressed("ability_throw"):
		do_throw()
	if _has_ability("pull") and Input.is_action_just_pressed("ability_pull"):
		do_pull()
	# Keep a held object floating in front of the Grabber.
	if _held != null:
		if is_instance_valid(_held):
			_carry_held()
		else:
			_held = null


## Where the camera is aimed: raycast forward up to `dist`, ignoring self.
func _aim_ray(dist: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * dist
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	return space.intersect_ray(q)


func _aim_forward() -> Vector3:
	return -camera.global_transform.basis.z


# --- Grapple-zip (STO-CHARACTER-025) ----------------------------------

## Instantly zip toward whatever surface the camera is aimed at.
func do_zip() -> void:
	var hit := _aim_ray(ZIP_RANGE)
	if hit.is_empty():
		return
	_zip_target = hit["position"]
	_zipping = true
	_zip_time = 0.0


## Test hook: zip to an explicit point (no aim needed).
func test_zip(point: Vector3) -> void:
	_zip_target = point
	_zipping = true
	_zip_time = 0.0


func is_zipping() -> bool:
	return _zipping


func _zip_move(delta: float) -> void:
	_zip_time += delta
	var to := _zip_target - global_position
	var d := to.length()
	if d < ZIP_STOP or _zip_time > ZIP_MAX_TIME:
		_zipping = false
		if d > 0.001:
			velocity = to / d * _speed  # slide out at walking speed
		return
	velocity = to / d * ZIP_SPEED


# --- Throw (STO-CHARACTER-026) -----------------------------------------

## First press grabs a nearby enemy/box; second press hurls it forward.
func do_throw() -> void:
	if _held == null or not is_instance_valid(_held):
		_grab_throwable()
	else:
		_release_throw()


func held_object() -> Node:
	return _held


func _grab_throwable() -> void:
	var target: Node = _nearest_enemy(THROW_GRAB_RANGE)
	if target == null:
		target = _nearest_grabbable(THROW_GRAB_RANGE)
	if target == null:
		return
	_held = target
	if _held.has_method("set_carried"):
		_held.call("set_carried", true)
	elif _held is RigidBody3D:
		(_held as RigidBody3D).freeze = true


func _release_throw() -> void:
	var obj := _held
	_held = null
	if not is_instance_valid(obj):
		return
	var fwd := _aim_forward() * THROW_FORCE + Vector3.UP * 3.0
	if obj.has_method("set_carried"):
		obj.call("set_carried", false)
		if obj.has_method("apply_knockback"):
			obj.call("apply_knockback", fwd)
	elif obj is RigidBody3D:
		(obj as RigidBody3D).freeze = false
		(obj as RigidBody3D).apply_central_impulse(fwd)


func _carry_held() -> void:
	var pos := global_position + Vector3.UP * 0.3 + _aim_forward() * THROW_HOLD_DIST
	var n := _held as Node3D
	if n != null:
		n.global_position = pos


# --- Pull (STO-CHARACTER-027) ------------------------------------------

## Yank the nearest enemy (or box) toward you.
func do_pull() -> void:
	var target: Node = _nearest_enemy(PULL_RANGE)
	if target == null:
		target = _nearest_grabbable(PULL_RANGE)
	if target == null:
		return
	var n := target as Node3D
	if n == null:
		return
	var toward := global_position - n.global_position
	toward.y = 0.0
	var dir := toward.normalized() if toward.length() > 0.001 else Vector3.ZERO
	var impulse := dir * PULL_FORCE + Vector3.UP * 3.0
	if target.has_method("apply_knockback"):
		target.call("apply_knockback", impulse)
	elif target is RigidBody3D:
		(target as RigidBody3D).apply_central_impulse(impulse)


# --- Block / parry (STO-CHARACTER-028) ---------------------------------

## Tapping guard shoves nearby enemies back (a parry); holding it blocks.
func do_parry() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n == null:
			continue
		var away := n.global_position - global_position
		away.y = 0.0
		if away.length() > PARRY_RANGE or away.length() < 0.001:
			continue
		if e.has_method("apply_knockback"):
			e.call("apply_knockback", away.normalized() * PARRY_PUSH + Vector3.UP * 4.0)


func set_block(on: bool) -> void:
	_blocking = on


## Test hook: set health directly (and clear the regen delay).
func set_health(h: float) -> void:
	_health = clampf(h, 0.0, _max_health)
	_regen_timer = 0.0


# --- Dodge roll (STO-CHARACTER-030) ------------------------------------

## A fast roll in the movement (or facing) direction; invincible while it lasts.
func do_dodge() -> void:
	if _rolling:
		return
	var input_dir := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if dir.length() < 0.01:
		dir = _aim_forward()
	dir.y = 0.0
	_roll_dir = dir.normalized() if dir.length() > 0.001 else -transform.basis.z
	_rolling = true
	_roll_time = 0.0


func _roll_move(delta: float) -> void:
	_roll_time += delta
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = _roll_dir.x * ROLL_SPEED
	velocity.z = _roll_dir.z * ROLL_SPEED
	if _roll_time >= ROLL_TIME:
		_rolling = false


func _nearest_grabbable(reach: float) -> Node:
	var best: Node = null
	var best_d := reach
	for n in get_tree().get_nodes_in_group("grabbable"):
		var node := n as Node3D
		if node == null:
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best


func _nearest_enemy(reach: float) -> Node:
	var best: Node = null
	var best_d := reach
	for e in get_tree().get_nodes_in_group("enemies"):
		var node := e as Node3D
		if node == null:
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best


## Rope/pendulum constraint: keep the player within grapple_length of the
## anchor. Cancels only the OUTWARD velocity, so tangential momentum (the
## swing) is preserved. A slight drag lets weak swings settle to a dangle.
func _apply_rope() -> void:
	var to_anchor := global_position - grapple_anchor
	var dist := to_anchor.length()
	if dist > grapple_length and dist > 0.001:
		var dir := to_anchor / dist
		global_position = grapple_anchor + dir * grapple_length
		var radial := velocity.dot(dir)
		if radial > 0.0:
			velocity -= dir * radial
	velocity *= GRAPPLE_DRAG


## Push movable RigidBodies we bump into (STO-WORLD-001 movable box).
## CharacterBody3D doesn't push physics bodies on its own, so give each
## one we slid against a nudge in our travel direction.
func _push_rigid_bodies() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D:
			var push := -col.get_normal()
			push.y = 0.0  # push sideways, don't shove things into the floor
			# When blocked against the box our speed drops to ~0, so use a
			# minimum push so contact still shoves it.
			var speed := Vector2(velocity.x, velocity.z).length()
			(collider as RigidBody3D).apply_central_impulse(
					push.normalized() * PUSH_IMPULSE * maxf(speed, 2.0))
