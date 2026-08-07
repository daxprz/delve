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

const BodyScript := preload("res://scripts/body.gd")

# Knockdown reactions (STO-ENEMIES-004/006): strong hits knock the
# enemy into a REAL physics ragdoll — RigidBody parts + joints built
# from its own procedural body at the moment of impact (ragdoll.gd).
# Momentum model (STO-ENEMIES-005): mass, center-of-mass height and
# stability derive from the procedurally-generated build. All hits are
# momentum transfers: dv = impulse / mass; the ragdoll parts inherit
# the enemy's OWN velocity plus the hit, so a tripped sprinter flies.
const DOWN_TIME := 1.6         # base knockdown time (scaled by mass)
const GETUP_TIME := 0.7        # base stand-up time (scaled by mass)
# Tiered reactions (STO-ENEMIES-007), thresholds on delivered dv and
# scaled by this build's stability. Stance is STRONG: it takes a real
# hit to stumble and a heavy one to go down.
const STUMBLE_DV := 3.0        # below this: a shove — moves a little, keeps coming
const KNOCKDOWN_DV := 7.5      # at/above this: ragdoll (was 5.0 — stance buffed)
const STUMBLE_TIME := 0.7      # steering lost while stumbling
const STUMBLE_LEAN := 0.22     # slight body dip toward the buckling side
const STUMBLE_BUCKLE := 1.15   # how far the bad leg folds (radians)
const RAGDOLL_TIMEOUT := 2.5   # extra seconds to wait for rest before forcing getup

const RagdollScript := preload("res://scripts/ragdoll.gd")

var _downed := 0.0
var _getup := 0.0
var _body_angle := 0.0          # getup blend: PI/2 (lying) -> 0 (upright)
var _getup_time := GETUP_TIME   # this individual's stand-up time
var _ragdoll: Node3D            # live EnemyRagdoll while knocked down
var _held_ragdoll := false      # held by the Grabber: stays limp
var _collider: CollisionShape3D

# Physical character, derived from the body's variation scales (_ready).
var _mass := 1.0                # relative mass (bulk^2 x build mix)
var _com_h := 1.2               # center-of-mass height (lever arm)
var _stability := 1.0           # resistance to being knocked down

var _stagger := 0.0
var _health := MAX_HEALTH
var _carried := false
var _stumble := 0.0             # stumble timer
var _stumble_axis := Vector3.RIGHT
var _stumble_leg := 0           # which leg buckles (0=L, 1=R)
var _last_target := ""  # for enemy/ai debug aspect (log on change only)
var _body: Node3D       # procedural humanoid (STO-ENEMIES-003)
var _base_color := Color(0.8, 0.2, 0.2)


func _ready() -> void:
	add_to_group("enemies")

	_collider = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	_collider.shape = cap
	_collider.position = Vector3(0.0, 0.8, 0.0)
	add_child(_collider)

	# A procedurally-generated humanoid body, like the player's
	# (STO-ENEMIES-003). Seeded from the node name so every enemy is a
	# distinct individual AND every peer renders the same one. The seed
	# also jitters the red tint a little.
	var vseed := name.hash()
	if vseed == 0:
		vseed = 1  # 0 means "no variation" to Body
	var rng := RandomNumberGenerator.new()
	rng.seed = vseed
	_base_color = Color(
			0.7 + rng.randf_range(0.0, 0.25),
			0.12 + rng.randf_range(0.0, 0.15),
			0.12 + rng.randf_range(0.0, 0.15))
	_body = BodyScript.new()
	_body.name = "Body"
	_body.set("build_human_arms", true)
	_body.set("use_fade", false)          # solid up close — not first-person
	_body.set("base_color", _base_color)
	_body.set("variation_seed", vseed)
	add_child(_body)

	# Physical character from the generated build (STO-ENEMIES-005):
	# wide/bulky -> heavy and stable; tall (long legs, high center of
	# mass) -> topples easier. Clamped so gameplay thresholds stay sane.
	var bk: float = _body.get("_bulk")
	var lg: float = _body.get("_leg_scale")
	var to: float = _body.get("_torso_scale")
	var hd: float = _body.get("_head_scale")
	_mass = clampf(bk * bk * (0.5 * to + 0.35 * lg + 0.15 * hd), 0.75, 1.5)
	_com_h = 0.92 * lg + 0.28 * to
	_stability = clampf(bk * 1.2 / _com_h, 0.85, 1.25)
	_getup_time = GETUP_TIME * (0.75 + 0.5 * _mass)

	# White eyes on the head so it keeps a visible "front".
	var head: Node3D = _body.get_node_or_null("Pelvis/Torso/Neck/Head")
	if head != null:
		for sx in [-1.0, 1.0]:
			var eye := MeshInstance3D.new()
			var es := SphereMesh.new()
			es.radius = 0.05
			es.height = 0.1
			eye.mesh = es
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(1, 1, 1)
			eye.material_override = em
			eye.position = Vector3(0.07 * float(sx), 0.03, -0.14)
			head.add_child(eye)


func _physics_process(delta: float) -> void:
	if _carried:
		return  # being carried by the Flyer — the player positions us

	if not multiplayer.is_server():
		return  # server drives the enemies

	if not is_on_floor():
		velocity += get_gravity() * delta

	var fall_speed := -velocity.y  # how fast we're dropping (before move)

	# Ragdolled: real physics owns the parts; we just track the pelvis
	# and wait for it to come to rest.
	if _ragdoll != null:
		_downed -= delta
		global_position = _ragdoll.call("pelvis_position")
		velocity = Vector3.ZERO
		DebugOverlay.draw_point3("enemy/hits", self, global_position,
				0.25, Color.RED)
		# A grabbed enemy stays limp for as long as it is held.
		if not _held_ragdoll and _downed <= 0.0 \
				and (bool(_ragdoll.call("at_rest")) or _downed < -RAGDOLL_TIMEOUT):
			_exit_ragdoll()
		return

	# Getting up: blend the body from lying back to upright.
	if _getup > 0.0:
		_getup -= delta
		_body_angle = move_toward(_body_angle, 0.0,
				(PI / 2.0 / _getup_time) * delta)
		if _body != null:
			_body.transform.basis = Basis(Vector3.RIGHT, _body_angle)
		if _getup <= 0.0:
			_body_angle = 0.0
			if _body != null:
				_body.transform.basis = Basis()
				_body.set_process(true)  # gait back on
			DebugOverlay.log("enemy/combat", self, "%s: back up", [name])
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
		move_and_slide()
		return

	# Stumble (STO-ENEMIES-008): the buckling leg does the work (see
	# Body.buckle_leg); the torso just dips toward the failing side and
	# recovers — a lurch, not a whole-body lean.
	if _stumble > 0.0:
		_stumble -= delta
		var t := clampf(_stumble / STUMBLE_TIME, 0.0, 1.0)
		if _body != null:
			_body.transform.basis = Basis(_stumble_axis,
					STUMBLE_LEAN * sin((1.0 - t) * PI)) \
					if t > 0.0 else Basis()

	if _stagger > 0.0:
		# Knocked back — let it slide, don't steer.
		_stagger -= delta
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
	else:
		var target := _nearest_player()
		var target_name: String = target.name if target != null else "(none)"
		if target_name != _last_target:
			DebugOverlay.log("enemy/ai", self, "%s: target %s -> %s",
					[name, _last_target if _last_target != "" else "(none)",
					target_name])
			_last_target = target_name
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


## Knock the enemy back (called by punch / shockwave / throw / parry).
## Momentum transfer: dv = impulse / mass. Delivered dv beyond this
## build's stability threshold bowls it over into a tumble.
func apply_knockback(impulse: Vector3) -> void:
	var dv := impulse / _mass
	if _ragdoll != null or dv.length() >= KNOCKDOWN_DV * _stability:
		# HARD: ragdoll. The dv goes into the ragdoll parts (launch
		# adds it to our CURRENT velocity) — adding it here too would
		# double the hit.
		_knockdown(dv, false)
	elif dv.length() >= STUMBLE_DV * _stability:
		# MEDIUM: stumble — shoved, loses its footing for a moment,
		# body lurches in the push direction, but stays up.
		DebugOverlay.draw_line3("enemy/hits", self,
				global_position + Vector3.UP * 1.2,
				global_position + Vector3.UP * 1.2 + dv * 0.25,
				Color.ORANGE, 0.7)
		velocity += dv
		velocity.y = maxf(velocity.y, dv.length() * 0.25)
		_stagger = STUMBLE_TIME
		_stumble = STUMBLE_TIME
		var dir := Vector3(dv.x, 0.0, dv.z)
		dir = dir.normalized() if dir.length() > 0.001 else -global_transform.basis.z
		var local_dir := (global_transform.basis.inverse() * dir).normalized()
		_stumble_axis = Vector3.UP.cross(local_dir)
		_stumble_axis = _stumble_axis.normalized() \
				if _stumble_axis.length() > 0.001 else Vector3.RIGHT
		# The leg on the side being shoved TOWARD is the one that gives
		# way (pushed right -> the right leg buckles under you).
		_stumble_leg = 1 if local_dir.x > 0.0 else 0
		if _body != null:
			# Slightly shorter than the stumble so the leg is back under
			# them just before steering returns (and so the two timers,
			# which tick in _process vs _physics_process, can't race).
			_body.call("buckle_leg", _stumble_leg, STUMBLE_TIME * 0.8,
					clampf(dv.length() / (KNOCKDOWN_DV * _stability), 0.4, 1.0))
		DebugOverlay.log("enemy/combat", self,
				"%s: stumbles, %s leg buckles (dv=%.1f)",
				[name, "R" if _stumble_leg == 1 else "L", dv.length()])
	else:
		# WEAK: just a shove — it shifts a little and keeps coming.
		DebugOverlay.draw_line3("enemy/hits", self,
				global_position + Vector3.UP * 1.2,
				global_position + Vector3.UP * 1.2 + dv * 0.25,
				Color.YELLOW, 0.7)
		velocity += dv


## Foot-sweep (the Runner's tail, mostly): a LOW hit — long lever arm,
## so it rotates harder than a body blow of the same momentum.
func trip(impulse: Vector3) -> void:
	if _carried:
		return
	var dv := impulse / _mass
	_knockdown(Vector3(dv.x, maxf(dv.y, 2.0), dv.z), true)


## Grabbed by the Grabber (STO-CHARACTER-044): go limp immediately and
## STAY limp until released, so it can be hauled around. Returns the
## live ragdoll so the arm can hold onto one of its parts.
func ragdoll_now() -> Node3D:
	if _ragdoll == null:
		_knockdown(Vector3.ZERO, false)
	_held_ragdoll = true
	return _ragdoll


## Let go of a held ragdoll — it drops and recovers on its own.
func release_ragdoll() -> void:
	if _held_ragdoll:
		_held_ragdoll = false
		_downed = maxf(_downed, 0.4)   # a moment on the floor before rising


func is_held_ragdoll() -> bool:
	return _held_ragdoll


## Put this enemy instantly back on its feet, discarding any ragdoll.
## Note a ragdolling enemy's POSITION is driven by its pelvis, so it
## must be recovered before it can be repositioned — moving the node
## alone would be undone on the next tick.
func recover() -> void:
	_held_ragdoll = false
	if _ragdoll != null:
		_exit_ragdoll(true)
	_downed = 0.0
	_getup = 0.0
	_stumble = 0.0
	_stagger = 0.0
	_body_angle = 0.0
	if _body != null:
		_body.transform.basis = Basis()
		_body.set_process(true)
	velocity = Vector3.ZERO


func is_downed() -> bool:
	return _ragdoll != null or _getup > 0.0


func is_stumbling() -> bool:
	return _stumble > 0.0


## The live ragdoll (null when standing) — for tests.
func ragdoll() -> Node3D:
	return _ragdoll


func mass() -> float:
	return _mass


func stability() -> float:
	return _stability


func _knockdown(dv: Vector3, swept: bool) -> void:
	# Already ragdolled: pump the extra momentum into the live parts.
	if _ragdoll != null:
		_ragdoll.call("shove", dv)
		_downed = maxf(_downed, DOWN_TIME * (0.75 + 0.5 * _mass))
		return
	var rag: Node3D = RagdollScript.new()
	rag.name = name + "Ragdoll"
	get_parent().add_child(rag)
	var parts: int = rag.call("build_from_body", _body, _mass)
	if parts == 0:
		rag.queue_free()  # body not ready (shouldn't happen) — stagger instead
		_stagger = STAGGER_TIME
		return
	# Momentum in: parts inherit our velocity + the hit dv. Sweeps
	# strike the shins (legs fly out); blows strike torso and head.
	rag.call("launch", velocity, dv,
			["ShinL", "ShinR"] if swept else ["Torso", "Head"])
	DebugOverlay.draw_line3("enemy/hits", self,
			global_position + Vector3.UP * 1.2,
			global_position + Vector3.UP * 1.2 + dv * 0.25, Color.RED, 0.7)
	_ragdoll = rag
	_body.visible = false
	_body.set_process(false)
	_collider.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	_downed = DOWN_TIME * (0.75 + 0.5 * _mass)  # heavy = down longer
	_getup = 0.0
	_stagger = 0.0
	Sounds.make(global_position, Sounds.RAGDOLL_LANDING)
	DebugOverlay.log("enemy/combat", self,
			"%s: ragdolled (%d parts, m=%.2f, dv=%.1f%s)",
			[name, parts, _mass, dv.length(), ", swept" if swept else ""])


func _exit_ragdoll(instant := false) -> void:
	if _ragdoll == null:
		return
	var pelvis: Vector3 = _ragdoll.call("pelvis_position")
	var headp: Vector3 = _ragdoll.call("head_position")
	_ragdoll.queue_free()
	_ragdoll = null
	global_position = Vector3(pelvis.x, pelvis.y + 0.1, pelvis.z)
	_collider.set_deferred("disabled", false)
	_body.visible = true
	_downed = 0.0
	if instant:
		_getup = 0.0
		_body_angle = 0.0
		_body.transform.basis = Basis()
		_body.set_process(true)
		return
	# Stand up out of the pose it landed in: face away from where the
	# head lies so the lying body matches, then blend upright.
	var lie := headp - pelvis
	lie.y = 0.0
	if lie.length() > 0.1:
		look_at(global_position - lie.normalized(), Vector3.UP)
	_body_angle = PI / 2.0
	_body.transform.basis = Basis(Vector3.RIGHT, _body_angle)
	_getup = _getup_time
	DebugOverlay.log("enemy/combat", self, "%s: getting up", [name])


## Take damage; at 0 health the enemy is defeated (STO-ENEMIES-002).
func take_damage(amount: float) -> void:
	_health -= amount
	# No damage flash (STO-ENEMIES-007): the physical reaction (shove /
	# stumble / ragdoll) IS the hit feedback; the body keeps its tint.
	DebugOverlay.log("enemy/combat", self, "%s: -%.0f hp -> %.0f",
			[name, amount, maxf(_health, 0.0)])
	if _health <= 0.0:
		DebugOverlay.log("enemy/combat", self, "%s: defeated", [name])
		if _ragdoll != null:
			_ragdoll.queue_free()  # don't orphan the physics parts
			_ragdoll = null
		queue_free()


## Carried by the Flyer (STO-CHARACTER-024): freeze AI/gravity while held.
func set_carried(on: bool) -> void:
	_carried = on
	if on:
		if _ragdoll != null:
			_exit_ragdoll(true)  # snap out of the ragdoll into the carry
		velocity = Vector3.ZERO


func health() -> float:
	return _health


func max_health() -> float:
	return MAX_HEALTH
