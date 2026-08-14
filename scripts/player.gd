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
const EchoVisionScript := preload("res://scripts/echo_vision.gd")
## Per-contact impulse used to push movable RigidBodies (scaled by speed).
const PUSH_IMPULSE := 0.12
## Newton's third law (STO-WORLD-005): shoving something that CAN'T
## move — a box jammed against a wall — pushes you back instead. How
## much of your blocked motion is returned, scaled by the object's mass
## relative to a nominal player.
const PUSH_REACTION := 0.6
const PUSH_TEST_DIST := 0.05   # probe: can the body move at all?
const PLAYER_MASS := 70.0

@onready var camera: Camera3D = $Camera3D

## Which character this player is (index into CharacterDB.LIST).
## -1 means "nobody told us": a player instanced directly (tests,
## single-player) then falls back to the menu selection. When main.gd
## spawns us it sets this explicitly from the lobby, and the value
## rides along with the spawn so every peer builds the same body.
var character := -1
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
## How far in front a held object floats, measured from the CAMERA
## (STO-CHARACTER-054). It used to be 1.6 m from the player's origin
## plus 0.3 m of height — knee level, tucked against the body, so it
## read as being pulled to you rather than held, and it sat in the way
## of the very aim you were lining up.
const THROW_HOLD_DIST := 2.4
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
# Pounce (STO-CHARACTER-032): the Runner crouches while Space is HELD
# on the ground, then springs forward+up on release. Charge scales the
# leap; a tap is still a normal jump.
const POUNCE_MIN_CHARGE := 0.18   # held less than this = ordinary jump
const POUNCE_MAX_CHARGE := 0.9    # seconds to a full-power pounce
const POUNCE_FORWARD := 7.5       # forward speed at full charge (halved)
const POUNCE_UP := 1.12           # up velocity multiplier at full charge
const POUNCE_CROUCH := 0.35       # how far the camera dips while charging
## Cooldown (STO-CHARACTER-033): a missed pounce locks the ability for
## 15 s, but LANDING one on an enemy refunds it instantly — chain
## pounces as long as you keep connecting.
const POUNCE_COOLDOWN := 15.0
const POUNCE_HIT_RANGE := 1.5     # how close counts as connecting
var _can_pounce := false
var _pounce_charge := 0.0
var _pouncing := false
var _pounce_cd := 0.0
var _pounce_hit := false
var _pounce_fill: ColorRect
var _cam_base_y := 1.6

## Wall jump: launch away from the wall + up.
const WALL_JUMP_PUSH := 7.0
const WALL_JUMP_UP := 1.05
const WALL_JUMP_LOCK := 0.25   # seconds the launch carries before input takes over
var _wall_lock := 0.0
## Brief window after being shoved back by a jammed object, during
## which walk input can't simply overwrite the rebound
## (STO-WORLD-005) — same trick as the wall-jump launch.
const PUSH_LOCK := 0.16
var _push_lock := 0.0
var _pre_move_velocity := Vector3.ZERO
## Echo-sight flag (the Sniper sees by sound alone).
var _blind := false

## Reel-in acceleration written by the mechanical arms each tick while
## an arm holds a solid anchor; consumed (and cleared) in
## _physics_process. Vector3.ZERO = not grappling.
var grapple_pull := Vector3.ZERO
const GRAPPLE_MAX_SPEED := 12.0

## The Sniper's rifle (STO-CHARACTER-047). A single shot reaches right
## across the map and floors what it hits — but the BANG floods the
## area with one enormous echo wave. That is how a blind Sniper looks
## around: you shoot to see, and everything hears you do it.
const GUN_RANGE := 140.0
const GUN_DAMAGE := 55.0
const GUN_KNOCKBACK := 17.0      # comfortably past any ragdoll threshold
const GUN_COOLDOWN := 1.6        # slow, deliberate, bolt-action
const GUN_BLAST_RADIUS := 45.0   # how far the shot's echo reaches
const GUN_IMPACT_RADIUS := 14.0  # smaller echo where the bullet lands
var _has_gun := false
var _gun_cd := 0.0
var _fire_held := false
var _gun_fill: ColorRect
var _shots_fired := 0
## Lidar scan on RMB (STO-CHARACTER-048): a quiet cone-shaped sweep
## that paints what's ahead and holds it for a few seconds. Unlike the
## rifle it doesn't shout your position across the map — but it only
## shows the direction you're facing.
const SCAN_COOLDOWN := 2.2
const SCAN_RANGE := 40.0
var _scan_cd := 0.0
var _scan_held := false
var _scans_done := 0

## Whether the player wants the mouse captured. We cannot capture in
## _ready() — on Wayland that errors until the pointer is actually
## over the window — so we capture lazily on the first mouse event.
var _capture_wanted := true

## Gentle mid-air steering used while a wall-jump launch is carrying.
const AIR_CONTROL := 10.0


func _enter_tree() -> void:
	# Node name is the owning peer id (set by main.gd _spawn_player);
	# each peer has authority over its own player.
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


## Find whoever can tell us our spawn slot, by walking up our own
## ancestors (Players -> the main scene).
##
## This used to ask get_tree().current_scene, which is null whenever
## the main scene was instantiated by hand rather than loaded as THE
## scene — every headless test does exactly that. The placement then
## did nothing at all, and the player was left wherever it started
## while the network raced to deliver a position (STO-CORE-007).
func _find_spawn_owner() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_method("spawn_position_for_peer"):
			return n
		n = n.get_parent()
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("spawn_position_for_peer"):
		return scene
	return null


func _ready() -> void:
	# Enemies look players up by group.
	add_to_group("players")

	# Players never collide with each other (STO-CORE-004).
	#
	# This is the real fix for the infinite-launch bug, not the spawn
	# spreading. A remote player's position comes from the network
	# sync, so it cannot be pushed aside; when two capsules overlap,
	# each instance shoves its OWN player upward to escape, syncs the
	# higher position, and shoves the other higher again. Both climb
	# forever. Spreading spawns only avoids the usual trigger —
	# walking into each other would set it off just the same.
	#
	# Collision exceptions are used rather than physics layers so that
	# everything else (world, enemies, the tail's rays, the Sniper's
	# echo) keeps seeing players exactly as before.
	for other in get_tree().get_nodes_in_group("players"):
		if other == self or not (other is CollisionObject3D):
			continue
		add_collision_exception_with(other)
		(other as CollisionObject3D).add_collision_exception_with(self)

	# Place OURSELVES at our spawn slot (STO-CORE-004). The host picks
	# a spot when it spawns us, but we own our own position — its
	# choice is overwritten by ours the moment we sync. Both sides
	# derive the same slot from the peer id, so this agrees with the
	# host rather than fighting it.
	if is_multiplayer_authority() and name.is_valid_int():
		var scene := _find_spawn_owner()
		if scene != null:
			position = scene.call("spawn_position_for_peer", name.to_int())
		else:
			# Silence here is what made STO-CORE-007 hide for so long:
			# the placement was skipped and the player was left at
			# whatever position it happened to have, with no complaint.
			push_warning("player %s: no spawn owner found, staying at %v"
					% [name, position])

	# Only the owning peer looks through this player's camera.
	camera.current = is_multiplayer_authority()

	# Set by whoever spawned us (main.gd) from the lobby choice, and
	# carried along with the spawn so every peer builds the same body.
	# It used to be read from CharacterDB here on the owner only, so
	# remote players all appeared as the Grabber.
	if character < 0:
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
	_can_pounce = def.get("pounce", false)
	_blind = bool(def.get("blind", false))
	_has_gun = bool(def.get("gun", false))
	_cam_base_y = camera.position.y
	_abilities = def.get("abilities", [])
	if is_multiplayer_authority():
		_build_hud()

	# A jointed humanoid body (STO-CHARACTER-012), for every character. The
	# owner's body fades near their camera (STO-CHARACTER-014); the Grabber
	# gets no human arms — its mechanical arms attach instead.
	var body: Node3D = BodyScript.new()
	body.name = "Body"
	body.set("build_human_arms", not _has_arms)
	# The Sniper has big listening ears (STO-CHARACTER-038).
	body.set("ears", bool(def.get("ears", false)))
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

	# The Sniper is blind and sees by echo (STO-CHARACTER-040). Only
	# the owning peer needs it — it is a way of SEEING, not a world
	# object, so remote copies of a Sniper are unaffected.
	if _blind and is_multiplayer_authority():
		# Camera renders ONLY the echo layer: the world itself is
		# never drawn, so the screen is black until something moves.
		camera.cull_mask = EchoVisionScript.ECHO_LAYER
		# Culling the world still left the SKY drawn behind it, so the
		# Sniper's view was a bright empty backdrop rather than
		# darkness. Give the camera its own pure-black environment
		# (STO-CHARACTER-051).
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0, 0, 0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0, 0, 0)
		env.ambient_light_energy = 0.0
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		camera.environment = env
		var echo: Node3D = EchoVisionScript.new()
		echo.name = "EchoVision"
		add_child(echo)

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
	DebugOverlay.log("player/combat", self, "%s: -%.0f hp -> %.0f/%.0f",
			[name, amount, _health, _max_health])
	if _health <= 0.0:
		DebugOverlay.log("player/combat", self, "%s: died, respawning", [name])
		_respawn()


## An enemy hit us (STO-ENEMIES-011).
##
## Enemy AI runs only on the server, but a player's health lives on the
## machine that OWNS that player — health is not a replicated property.
## So the server cannot just call take_damage on its own copy of a
## remote player: it would drain a health bar nobody is looking at,
## while the real player felt nothing.
func hurt_by_enemy(amount: float) -> void:
	if is_multiplayer_authority():
		take_damage(amount)
	else:
		_remote_enemy_damage.rpc_id(get_multiplayer_authority(), amount)


## Sent by the server to whoever owns this player. "any_peer" rather
## than "authority" because the sender is the SERVER, while this node's
## authority is the owning client — so we check the sender by hand.
@rpc("any_peer", "call_remote", "reliable")
func _remote_enemy_damage(amount: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return          # only the server decides that an enemy hit you
	take_damage(amount)


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
	DebugOverlay.log("player/combat", self, "%s: hit %s for %.0f (combo x%d)",
			[name, target.name, amount * mult, _combo])


func combo() -> int:
	return _combo


## Fire the rifle: a hitscan shot along the aim, and one enormous
## echo blast from the muzzle that lights the room (STO-CHARACTER-047).
func fire_gun() -> void:
	_gun_cd = GUN_COOLDOWN
	_shots_fired += 1
	var from := camera.global_position
	var aim := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + aim * GUN_RANGE)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)

	# The bang: one huge wave from the muzzle. This is the Sniper's
	# only way to see a room properly — and it announces exactly where
	# it was fired from.
	var echo := get_node_or_null("EchoVision")
	if echo != null:
		echo.call("emit_blast", from, GUN_BLAST_RADIUS)
	# Everyone hears a gunshot, on every machine.
	Sounds.make(from, Sounds.GUNSHOT)

	if hit.is_empty():
		DebugOverlay.log("player/abilities", self, "%s: gunshot (missed)", [name])
		return
	var target = hit.get("collider")
	var point: Vector3 = hit["position"]
	# A second, smaller echo where the bullet strikes, so you can read
	# what you hit even at the far end of the room.
	if echo != null:
		echo.call("emit_blast", point, GUN_IMPACT_RADIUS)
	if target != null and target.has_method("take_damage"):
		if target.has_method("apply_knockback"):
			# `point` is where the bullet actually struck, so a shot to
			# the head can take the head off (STO-ENEMIES-012).
			target.call("apply_knockback", aim * GUN_KNOCKBACK, point)
		deal_damage(target, GUN_DAMAGE)
		DebugOverlay.log("player/abilities", self, "%s: gunshot hit %s",
				[name, target.name])
	else:
		DebugOverlay.log("player/abilities", self,
				"%s: gunshot hit the world at (%.1f, %.1f, %.1f)",
				[name, point.x, point.y, point.z])


## Sweep a lidar cone where you're looking (STO-CHARACTER-048). The
## points it paints hold for a few seconds and then fade, so a scan is
## a steady look ahead rather than the rifle's one-off flash — and it
## doesn't announce you the way a gunshot does.
func lidar_scan() -> void:
	var echo := get_node_or_null("EchoVision")
	if echo == null:
		return
	_scan_cd = SCAN_COOLDOWN
	_scans_done += 1
	echo.call("emit_scan", camera.global_position,
			-camera.global_transform.basis.z, SCAN_RANGE)
	DebugOverlay.log("player/abilities", self, "%s: lidar scan", [name])


func scan_cooldown() -> float:
	return maxf(_scan_cd, 0.0)


func scans_done() -> int:
	return _scans_done


func gun_cooldown() -> float:
	return maxf(_gun_cd, 0.0)


func shots_fired() -> int:
	return _shots_fired


## Seconds left on the pounce cooldown (0 = ready). For HUD/tests.
func pounce_cooldown() -> float:
	return maxf(_pounce_cd, 0.0)


func is_pouncing() -> bool:
	return _pouncing


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

	# Sniper: a bar showing when the next shot is ready.
	if _has_gun:
		var gbg := ColorRect.new()
		gbg.color = Color(0, 0, 0, 0.55)
		gbg.size = Vector2(224, 20)
		gbg.anchor_top = 1.0
		gbg.anchor_bottom = 1.0
		gbg.offset_left = 20
		gbg.offset_top = -78
		gbg.offset_right = 244
		gbg.offset_bottom = -58
		hud.add_child(gbg)
		_gun_fill = ColorRect.new()
		_gun_fill.color = Color(0.9, 0.85, 0.4)
		_gun_fill.position = Vector2(2, 2)
		_gun_fill.size = Vector2(220, 16)
		gbg.add_child(_gun_fill)

	# Pounce characters: a bar that empties on use and refills as the
	# cooldown ticks down — green when ready (STO-CHARACTER-033).
	if _can_pounce:
		var pbg := ColorRect.new()
		pbg.color = Color(0, 0, 0, 0.55)
		pbg.size = Vector2(224, 20)
		pbg.anchor_top = 1.0
		pbg.anchor_bottom = 1.0
		pbg.offset_left = 20
		pbg.offset_top = -78
		pbg.offset_right = 244
		pbg.offset_bottom = -58
		hud.add_child(pbg)
		_pounce_fill = ColorRect.new()
		_pounce_fill.color = Color(0.3, 0.85, 0.4)
		_pounce_fill.position = Vector2(2, 2)
		_pounce_fill.size = Vector2(220, 16)
		pbg.add_child(_pounce_fill)


func _process(_delta: float) -> void:
	if _hp_fill != null and _max_health > 0.0:
		_hp_fill.size.x = 220.0 * (_health / _max_health)
	if _fuel_fill != null:
		_fuel_fill.size.x = 220.0 * clampf(_fly_fuel / FLY_MAX_FUEL, 0.0, 1.0)
	if _gun_fill != null:
		var loaded := 1.0 - clampf(_gun_cd / GUN_COOLDOWN, 0.0, 1.0)
		_gun_fill.size.x = 220.0 * loaded
		_gun_fill.color = Color(0.9, 0.85, 0.4) if _gun_cd <= 0.0 \
				else Color(0.6, 0.4, 0.2)
	if _pounce_fill != null:
		var ready := 1.0 - clampf(_pounce_cd / POUNCE_COOLDOWN, 0.0, 1.0)
		_pounce_fill.size.x = 220.0 * ready
		# Green when ready to leap, amber while recharging.
		_pounce_fill.color = Color(0.3, 0.85, 0.4) if _pounce_cd <= 0.0 \
				else Color(0.85, 0.65, 0.2)


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

	# Pounce (STO-CHARACTER-032): holding Space on the ground crouches
	# and charges; releasing springs forward. Handled BEFORE the normal
	# jump so a held Space charges instead of hopping.
	if _can_pounce:
		if _pounce_cd > 0.0:
			_pounce_cd -= delta
		# While airborne on a pounce, connecting with an enemy refunds
		# the cooldown — reward for actually landing it.
		if _pouncing and not _pounce_hit:
			var target := _nearest_enemy(POUNCE_HIT_RANGE)
			if target != null:
				_pounce_hit = true
				_pounce_cd = 0.0
				DebugOverlay.log("player/abilities", self,
						"%s: pounce HIT %s — cooldown refunded",
						[name, target.name])
		# Charging is only possible when the pounce is off cooldown. If
		# it isn't, we fall through to the ordinary jump below, which
		# fires instantly on press (STO-CHARACTER-036) — the Runner must
		# never be unable to jump.
		if Input.is_action_pressed("jump") and is_on_floor() \
				and not _pouncing and _pounce_cd <= 0.0:
			_pounce_charge += delta
			# Crouch down as you coil, and hold still.
			var t := clampf(_pounce_charge / POUNCE_MAX_CHARGE, 0.0, 1.0)
			camera.position.y = _cam_base_y - POUNCE_CROUCH * t
			velocity.x = move_toward(velocity.x, 0.0, _speed * 3.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, _speed * 3.0 * delta)
			move_and_slide()
			return
		elif _pounce_charge > 0.0:
			var t := clampf(_pounce_charge / POUNCE_MAX_CHARGE, 0.0, 1.0)
			camera.position.y = _cam_base_y
			if _pounce_charge >= POUNCE_MIN_CHARGE:
				var fwd := -transform.basis.z
				fwd.y = 0.0
				fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
				velocity = fwd * POUNCE_FORWARD * t
				velocity.y = _jump * (1.0 + (POUNCE_UP - 1.0) * t)
				_jumps_used = 1
				_pouncing = true
				_pounce_hit = false
				_pounce_cd = POUNCE_COOLDOWN  # refunded if we connect
				_wall_lock = WALL_JUMP_LOCK  # keep the launch through input
				Sounds.make(global_position, Sounds.POUNCE)
				DebugOverlay.log("player/abilities", self,
						"%s: pounce (charge %.2f s, power %.0f%%)",
						[name, _pounce_charge, t * 100.0])
			else:
				velocity.y = _jump  # a tap is just a jump
				_jumps_used = 1
			_pounce_charge = 0.0
		# Only end the pounce once we've actually come back DOWN — on the
		# launch tick we're still touching the floor with velocity.y > 0.
		if _pouncing and is_on_floor() and velocity.y <= 0.0:
			_pouncing = false

	# Jump — from the floor, off a wall (wall-jump characters), or a mid-air
	# double jump (double-jump characters). Pounce characters handle the
	# GROUND case above (hold to charge); their air jumps still land here.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Pounce characters normally charge instead of hopping — but
			# while the pounce is recharging there is nothing to charge,
			# so Space is an ordinary jump, instantly (STO-CHARACTER-036).
			if not _can_pounce or _pounce_cd > 0.0:
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
	if _push_lock > 0.0:
		_push_lock -= delta

	# While an arm is reeling us in, walk input must not damp the pull
	# away: without this the ground friction cancels all but a single
	# tick of it every frame and the grapple barely moves you.
	var grappling := grapple_pull != Vector3.ZERO
	if _wall_lock > 0.0 or _push_lock > 0.0 or grappling \
			or (_pouncing and not is_on_floor()):
		# Keep momentum through a wall-jump launch or a pounce arc:
		# only gentle steering, never a hard damp to walk speed.
		if direction:
			velocity += direction * AIR_CONTROL * delta
	else:
		if direction:
			velocity.x = direction.x * spd
			velocity.z = direction.z * spd
		else:
			velocity.x = move_toward(velocity.x, 0.0, _speed)
			velocity.z = move_toward(velocity.z, 0.0, _speed)

	# The Sniper's rifle (STO-CHARACTER-047).
	if _has_gun:
		if _gun_cd > 0.0:
			_gun_cd -= delta
		var firing := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
				and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if firing and not _fire_held and _gun_cd <= 0.0:
			fire_gun()
		_fire_held = firing

		if _scan_cd > 0.0:
			_scan_cd -= delta
		var scanning := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
				and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if scanning and not _scan_held and _scan_cd <= 0.0:
			lidar_scan()
		_scan_held = scanning

	# Grapple reel-in from the mechanical arms (STO-CHARACTER-044).
	# Applied AFTER the walk input, which overwrites velocity.x/z every
	# tick and would otherwise erase the pull entirely.
	if grapple_pull != Vector3.ZERO:
		velocity += grapple_pull * delta
		# Cap the speed we can be reeled at, so a grapple is a brisk
		# haul rather than a rocket into the wall.
		var reel_dir := grapple_pull.normalized()
		var along := velocity.dot(reel_dir)
		if along > GRAPPLE_MAX_SPEED:
			velocity -= reel_dir * (along - GRAPPLE_MAX_SPEED)
		grapple_pull = Vector3.ZERO

	# move_and_slide() rewrites `velocity` with the RESOLVED motion, so
	# a blocked push reads as ~0 afterwards. Keep what we intended, so
	# the push reaction knows how hard we were actually shoving.
	_pre_move_velocity = velocity
	move_and_slide()

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
	# C and G are DEAD KEYS (STO-CHARACTER-056).
	#
	# G was the throw — RMB does that now, and better
	# (STO-CHARACTER-055), so it was a worse version of a job already
	# taken. C was block, parry and dodge-roll, and the operator chose
	# to drop it knowing what it costs: since STO-ENEMIES-011 enemies
	# actually attack, this leaves NO defence but footwork. Walking out
	# of range during the 0.55 s wind-up is now the only answer.
	#
	# do_parry / do_dodge / do_throw are deliberately still here, just
	# unreachable from the keyboard, so putting them on another key is
	# one line rather than a rewrite.
	if _has_ability("zip") and Input.is_action_just_pressed("ability_zip"):
		do_zip()
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
	DebugOverlay.log("player/abilities", self, "%s: zip -> (%.1f, %.1f, %.1f)",
			[name, _zip_target.x, _zip_target.y, _zip_target.z])


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
	DebugOverlay.log("player/abilities", self, "%s: grabbed %s", [name, target.name])
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
	# From the camera, so it sits at eye level and follows the look
	# direction up and down instead of hovering by the player's knees.
	var pos := camera.global_position + _aim_forward() * THROW_HOLD_DIST
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
	DebugOverlay.log("player/abilities", self, "%s: dodge roll", [name])


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


## Measured to the enemy's MIDDLE, not its origin.
##
## An enemy's origin sits at its feet while its capsule is 1.6 m tall,
## so measuring origin-to-origin overstates the distance badly whenever
## there is any height between you — standing on an enemy's head reads
## as 1.6 m away, which is further than a pounce can reach.
##
## That went unnoticed until enemies learned to stop and wind up an
## attack (STO-ENEMIES-011): before that they walked right into you and
## there was never any height to get wrong. Suddenly you could land ON
## one, and a pounce that visibly connected refused to count.
const ENEMY_CENTRE_Y := 0.8

func _nearest_enemy(reach: float) -> Node:
	var best: Node = null
	var best_d := reach
	for e in get_tree().get_nodes_in_group("enemies"):
		var node := e as Node3D
		if node == null:
			continue
		var d := global_position.distance_to(
				node.global_position + Vector3.UP * ENEMY_CENTRE_Y)
		if d < best_d:
			best_d = d
			best = node
	return best


## Push movable RigidBodies we bump into (STO-WORLD-001 movable box).
## CharacterBody3D doesn't push physics bodies on its own, so give each
## one we slid against a nudge in our travel direction.
func _push_rigid_bodies() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D:
			var rb := collider as RigidBody3D
			var push := -col.get_normal()
			push.y = 0.0  # push sideways, don't shove things into the floor
			if push.length() < 0.001:
				continue
			push = push.normalized()
			# When blocked against the box our speed drops to ~0, so use a
			# minimum push so contact still shoves it.
			var speed := Vector2(velocity.x, velocity.z).length()
			rb.apply_central_impulse(push * PUSH_IMPULSE * maxf(speed, 2.0))

			# If the thing we're shoving has nowhere to go, the push
			# comes back into US (STO-WORLD-005).
			if not _body_can_move(rb, push):
				# How hard we were shoving BEFORE the collision ate it.
				var into := _pre_move_velocity.dot(push)
				if into > 0.0:
					# Rebound is a FRACTION of the push we were making,
					# scaled by how heavy the thing is: a light crate
					# jammed against a wall just stops you with a nudge,
					# something heavy genuinely shoves you back.
					var mass_ratio := clampf(rb.mass / PLAYER_MASS, 0.25, 1.5)
					velocity -= push * into * PUSH_REACTION * mass_ratio
					# Hold the rebound briefly, or the walk input would
					# overwrite velocity on the very next tick.
					_push_lock = PUSH_LOCK
					DebugOverlay.log("player/movement", self,
							"%s: shoved %s into something solid — pushed back %.1f m/s",
							[name, rb.name, into * PUSH_REACTION * mass_ratio])


## Can this body actually move in `dir`, or is it jammed against
## something solid? Probes a short test motion (STO-WORLD-005).
func _body_can_move(rb: RigidBody3D, dir: Vector3) -> bool:
	var params := PhysicsTestMotionParameters3D.new()
	params.from = rb.global_transform
	params.motion = dir * PUSH_TEST_DIST
	params.exclude_bodies = [get_rid()]
	return not PhysicsServer3D.body_test_motion(rb.get_rid(), params)
