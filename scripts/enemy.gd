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
const QuadrupedScript := preload("res://scripts/quadruped_body.gd")
const EnemyKinds := preload("res://scripts/enemy_kinds.gd")

## Which KIND of enemy this is (STO-ENEMIES-017), an index into
## EnemyKinds.LIST. Replicated with the spawn, so every peer builds
## the same creature rather than each machine guessing.
@export var kind: int = 0

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

# Attacks (STO-ENEMIES-011). Until now enemies chased and did nothing,
# so nothing in delve could hurt you — health, healing, the Grabber's
# guard and the Runner's dodge roll all existed with no threat to use
# them against.
#
# A swing is deliberately slow and telegraphed: the enemy stops, rears
# back for ATTACK_WINDUP seconds, and only then does damage. Being hit
# should always be a thing you could have avoided.
const ATTACK_RANGE := 2.2       # how close it must be to swing
const ATTACK_DAMAGE := 12.0     # a full-strength hit
const ATTACK_WINDUP := 0.55     # telegraph before the blow lands
const ATTACK_COOLDOWN := 1.8    # rest between swings
const ATTACK_LEAN := 0.30       # how far it rears back while winding up
## The hit is checked again at the END of the wind-up, from slightly
## further out than the trigger range — step away and it misses, but a
## hair of tolerance stops it feeling like it whiffed unfairly.
const ATTACK_REACH := 2.6

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
## Filled in from the kind (STO-ENEMIES-017).
var _kind_id := "walker"
var _max_health := MAX_HEALTH
var _kind_speed := SPEED
var _can_climb := false
var _kind_damage := ATTACK_DAMAGE
var _carried := false
# Limbs (EPI-ENEMIES-ENEMY-LIMBS). A limb is a friendly name for the
# ragdoll part it hangs off; taking the part off takes everything
# below it too (an upper arm brings its forearm).
const LIMBS := {
	"head": "Head",
	"arm_l": "UpperArmL",
	"arm_r": "UpperArmR",
	"leg_l": "ThighL",
	"leg_r": "ThighR",
}
## How hard a blow has to be to tear a limb off. Well above
## KNOCKDOWN_DV (7.5): knocking something over is common, pulling it
## apart should not be.
const DISMEMBER_DV := 14.0
## Losing one leg leaves a limp, not a kill (STO-ENEMIES-014).
const ONE_LEG_SPEED := 0.40
## Losing one arm guts the damage; losing both means it cannot hurt
## you at all, though it will still follow you around (STO-ENEMIES-015).
const ONE_ARM_DAMAGE := 0.35
var _lost: Array = []           # limb keys already torn off
## Corpses (STO-ENEMIES-016): a dead enemy leaves its ragdoll behind
## instead of vanishing. Capped, because each body is 11 rigid parts.
const MAX_CORPSES := 8
var _dead := false
# Clambering (STO-ENEMIES-027) — the spider's trick, not the Walker's.
# Four splayed legs getting over an obstacle is what a spider is for,
# and nothing else in delve leaves the floor except the Flyer.
#
# It gets over THINGS but not WALLS, and it decides which is which by
# asking one question of the world: can I see the top of this from
# here? A crate, yes. A ten-metre wall, no. That single measurement is
# the whole rule, so an obstacle nobody anticipated still gets the
# right answer. This REPLACES the climb-anything behaviour of
# STO-ENEMIES-024, which made the big wall pointless.
const CLIMB_SPEED := 2.2       # how fast it goes up
const CLIMB_REACH := 1.1       # how close an obstacle has to be to grip
## Fallback reach for a climber with no procedural body to measure.
const CLAMBER_FALLBACK := 2.4
## Head-on-ness below which sliding cannot help and we must pick a side
## deliberately. A tangent this short means we are square to the wall.
const WALL_TANGENT_MIN := 0.25
var _climbing := false
## True while a too-tall obstacle is turning us aside (for tests).
var _skirting := false
## The face of whatever is currently in the way. Kept so that code
## running LATER in the tick — the dragging spider, in particular — can
## steer around the same obstacle the chase logic already found,
## instead of each place probing the world again and disagreeing.
var _block_normal := Vector3.ZERO

# --- The mind (STO-ENEMIES-038 + EPI-ENEMIES-SPIDER-LEARNS) ----------
#
# Only the spider has one. Everything else in delve still finds you by
# looking up the nearest player, which is fine for a Walker: a creature
# that is meant to be a fight does not need to be clever.
const MindScript := preload("res://scripts/spider_mind.gd")
## How long a plan lasts before it picks another and scores the last.
const PLAN_TIME := 5.0
var _mind: Node = null
var _plan_timer := 0.0
var _plan_started_at := INF     # distance to prey when the plan began

# --- Taking you away (EPI-ENEMIES-SPIDER-TAKES-YOU) -------------------
#
# Reach → catch → SMASH you into the ground → drag you along the floor →
# put you on a spike → walk away. Only a creature with pincer arms can
# do any of it; a Walker never enters this state machine at all.

enum { TAKE_NONE, TAKE_REACH, TAKE_SMASH, TAKE_DRAG, TAKE_LEAVE }

## How much closer than full arm's length you must be before it stops
## reaching and actually closes on you. Derived from the arms at runtime
## (see `_pincer_reach`), never typed in.
const GRAB_FRACTION := 0.55
## Extra distance beyond arm's reach at which the arms START unfolding.
## This margin IS the warning (STO-ENEMIES-048).
const REACH_MARGIN := 2.5
## The slam. One hard hit, and much bigger than a normal swing — being
## caught by this thing has to frighten you (STO-ENEMIES-031).
const SMASH_DAMAGE := 34.0
const SMASH_TIME := 0.45        # how long the slam takes
## Where you are held while dragged: behind the spider, on the floor.
const DRAG_BEHIND := 1.4
const DRAG_HEIGHT := 0.35
const DRAG_SPEED_SCALE := 0.85  # it is carrying someone; it slows a little
## Close enough to the spike to put you on it.
const IMPALE_RANGE := 1.8
## Further than this from the spider and the grip is lost. Generously
## more than DRAG_BEHIND, so ordinary dragging never trips it — this is
## for the cases where a victim ends up somewhere they cannot have
## walked to, which the game has several ways of causing.
const LOST_GRIP := 6.0
## How long it walks away for before it will hunt again. Long enough
## that being left on the spike is a real, quiet, horrible pause.
const LEAVE_TIME := 4.0

var _take := TAKE_NONE
var _prey: Node3D = null        # who we have hold of
var _take_timer := 0.0
var _spike: Node3D = null       # where we are taking them
var _takes := 0                 # how many players taken (tests read this)

var _windup := 0.0              # >0 while rearing back to strike
var _attack_cd := 0.0           # rest timer between swings
var _swings := 0                # how many blows landed (tests read this)
var _stumble := 0.0             # stumble timer
var _stumble_axis := Vector3.RIGHT
var _stumble_leg := 0           # which leg buckles (0=L, 1=R)
var _last_target := ""  # for enemy/ai debug aspect (log on change only)
var _body: Node3D       # procedural humanoid (STO-ENEMIES-003)
var _base_color := Color(0.8, 0.2, 0.2)


func _ready() -> void:
	add_to_group("enemies")
	var def := EnemyKinds.get_def(kind)
	_kind_id = String(def["id"])
	_max_health = float(def["health"])
	_health = _max_health
	_kind_speed = float(def["speed"])
	_kind_damage = float(def["damage"])
	_can_climb = bool(def.get("climbs", false))

	_collider = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	_collider.shape = cap
	_collider.position = Vector3(0.0, 0.8, 0.0)
	add_child(_collider)
	# Resized below for kinds that are not humanoid — a towering
	# spider with a human-sized hitbox would let you punch thin air.

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
	if String(EnemyKinds.get_def(kind)["body"]) == "quadruped":
		# Four legs and a block (STO-ENEMIES-018).
		_body = QuadrupedScript.new()
		_body.name = "Body"
		_body.set("base_color", Color(EnemyKinds.get_def(kind)["colour"]))
		_body.set("variation_seed", vseed)
		add_child(_body)
		# Only the spider gets a mind. It loads what it already knows
		# about people the moment it exists — the operator asked for it
		# to remember forever, and forever has to start before the first
		# frame or the first minute of every session is amnesia.
		_mind = MindScript.new(vseed)
		_mind.load_memory()
	else:
		_body = BodyScript.new()
		_body.name = "Body"
		_body.set("build_human_arms", true)
		_body.set("use_fade", false)      # solid up close — not first-person
		_body.set("base_color", _base_color)
		_body.set("variation_seed", vseed)
		add_child(_body)

	# Physical character from the generated build (STO-ENEMIES-005):
	# wide/bulky -> heavy and stable; tall (long legs, high center of
	# mass) -> topples easier. Clamped so gameplay thresholds stay sane.
	if _kind_id != "walker":
		# The humanoid's build numbers do not exist on other bodies;
		# give a quadruped sane physical character and stop.
		var qs: Vector3 = _body.call("body_size")
		_mass = clampf(qs.x * qs.z * 5.0, 0.6, 1.3) * 2.4   # giant
		_com_h = 0.55
		# Four huge legs braced wide: it takes a far harder hit to
		# topple than anything on two (STO-ENEMIES-021). Sturdy, not
		# invincible — a big enough blow still puts it down.
		_stability = 3.2
		_getup_time = GETUP_TIME * (0.75 + 0.5 * _mass)
		# Hitbox to match: tall enough to reach its body, wide enough
		# to cover the legs (STO-ENEMIES-020).
		var bh: float = _body.call("body_height")
		var qcap := _collider.shape as CapsuleShape3D
		qcap.height = maxf(bh + qs.y, 1.0)
		qcap.radius = maxf(qs.x * 1.6, 0.5)
		_collider.position = Vector3(0.0, qcap.height * 0.5, 0.0)
		return
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

	# What is in front of us, and is it a thing or a wall? Probed along
	# the way we WANT to go, not the way we are drifting, so a spider
	# shoved sideways still judges the obstacle it is walking into
	# (STO-ENEMIES-027).
	var hunted := _hunt(delta)
	var want := Vector3.ZERO
	if hunted != null:
		want = hunted.global_position - global_position
		want.y = 0.0
	else:
		want = Vector3(velocity.x, 0.0, velocity.z)
	var blocking: Dictionary = {}
	if _can_climb and not _dead and _ragdoll == null:
		blocking = _probe_ahead(want)
	# Gripping an obstacle holds it up, so gravity is off while it
	# clambers. A wall it cannot get over grants no such grip.
	_climbing = bool(blocking.get("over", false))
	_skirting = not blocking.is_empty() and not _climbing
	_block_normal = blocking.get("normal", Vector3.ZERO)
	if not is_on_floor() and not _climbing:
		velocity += get_gravity() * delta

	var fall_speed := -velocity.y  # how fast we're dropping (before move)

	# Ragdolled: real physics owns the parts; we just track the pelvis
	# and wait for it to come to rest.
	if _ragdoll != null:
		# Knocked down mid-carry, it lets go. Being bowled over while it
		# is dragging you off is the one moment you get for free, and it
		# would be absurd for a limp creature to keep its grip.
		if _take != TAKE_NONE:
			_drop_prey("knocked down")
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

	# Taking you away (EPI-ENEMIES-SPIDER-TAKES-YOU). Handled before the
	# ordinary attack and chase logic, because a spider that has hold of
	# someone is not looking for anyone to swing at.
	if _pincer_arms() != null and _update_take(delta):
		move_and_slide()
		if _body != null and _body.has_method("set_speed"):
			_body.call("set_speed", Vector2(velocity.x, velocity.z).length())
		return

	# Attacking (STO-ENEMIES-011). Handled before the chase logic so a
	# winding-up enemy plants its feet instead of walking through you.
	if _attack_cd > 0.0:
		_attack_cd -= delta
	if _windup > 0.0:
		_windup -= delta
		# Rear back, then snap through. The lean IS the telegraph.
		if _body != null:
			var t := 1.0 - clampf(_windup / ATTACK_WINDUP, 0.0, 1.0)
			_body.transform.basis = Basis(Vector3.RIGHT, -ATTACK_LEAN * sin(t * PI))
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
		if _windup <= 0.0:
			if _body != null:
				_body.transform.basis = Basis()
			_land_blow()
		move_and_slide()
		return

	if _stagger > 0.0:
		# Knocked back — let it slide, don't steer.
		_stagger -= delta
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
	else:
		var target := hunted
		var target_name: String = target.name if target != null else "(none)"
		if target_name != _last_target:
			DebugOverlay.log("enemy/ai", self, "%s: target %s -> %s",
					[name, _last_target if _last_target != "" else "(none)",
					target_name])
			_last_target = target_name
		# Where to go. A creature with a mind aims where it thinks you
		# are GOING, and when it cannot sense anybody it walks to the
		# last place it knew of instead of standing still — which is the
		# difference between hunting and being a magnet.
		var goal := Vector3.INF
		if target != null:
			goal = _mind.aim_at(target) if _mind != null \
					else target.global_position
		elif _mind != null and _mind.hunting_memory():
			goal = _mind.last_known()
			if _mind.reached_memory(global_position):
				_mind.trail_cold()      # got there, nobody home
				goal = Vector3.INF

		if goal.is_finite():
			var to := goal - global_position
			to.y = 0.0
			if to.length() > 0.6:  # stop when basically on top of them
				var dir := to.normalized()
				# Tried this way and got nowhere? Go a different way
				# (STO-ENEMIES-044). Checked before the obstacle rules
				# so a spider that has decided to try something else is
				# not immediately steered back into what failed.
				if _mind != null and _mind.is_detouring():
					dir = (dir + Vector3.UP.cross(dir).normalized()
							* _mind.detour_side() * 1.2).normalized()
				# Too big to climb? Follow the face of it instead of
				# grinding into it, so it hunts its way around rather
				# than standing there pressed against the stone.
				elif _skirting:
					dir = _around(dir, blocking.get("normal", Vector3.ZERO))
				var spd := _move_speed()
				velocity.x = dir.x * spd
				velocity.z = dir.z * spd
				# Something climbable in the way? Go UP it. Not
				# conditioned on where the player is: the obstacle is
				# the reason to climb, and the probe stops seeing it
				# once we are over the top, which ends the climb by
				# itself.
				if _climbing:
					velocity.y = CLIMB_SPEED
				look_at(global_position + dir, Vector3.UP)
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	var was_at := global_position
	# Whether it was TRYING to go anywhere, read BEFORE move_and_slide:
	# this is intent, and intent is what makes "I got nowhere" mean
	# something. Read afterwards it would be indistinguishable from
	# having been stopped by a wall.
	var trying := Vector2(velocity.x, velocity.z).length() > 0.05
	move_and_slide()
	# How far it ACTUALLY got — after the walls, not before them. This
	# is what it practises against and what tells it it is stuck.
	_think_about_moving(was_at.distance_to(global_position), delta, trying)

	# Tell a four-legged body how fast it is actually travelling, so
	# its legs step in time with the ground instead of running on the
	# spot (STO-ENEMIES-018).
	if _body != null and _body.has_method("set_speed"):
		_body.call("set_speed", Vector2(velocity.x, velocity.z).length())

	# Close enough to swing? Start the wind-up (STO-ENEMIES-011).
	if _attack_cd <= 0.0 and _windup <= 0.0 and not _carried:
		var prey := _nearest_player()
		if prey != null and _can_strike(prey, ATTACK_RANGE):
			_windup = ATTACK_WINDUP
			_attack_cd = ATTACK_COOLDOWN + ATTACK_WINDUP
			DebugOverlay.log("enemy/combat", self, "%s: winding up at %s",
					[name, prey.name])

	# Fall damage: landing hard (e.g. dropped from height) hurts.
	if is_on_floor() and fall_speed > FALL_SAFE_SPEED:
		take_damage((fall_speed - FALL_SAFE_SPEED) * FALL_DAMAGE_SCALE)


# --- The mind (STO-ENEMIES-038 + EPI-ENEMIES-SPIDER-LEARNS) ----------

## Who this creature is going after this frame.
##
## A Walker looks up the nearest player and always will — it is meant
## to be a fight, not a hunt. The spider **feels for you**, and if it
## feels nothing it does not stop existing: it keeps whatever it last
## knew, which the chase code then walks to.
func _hunt(delta: float) -> Node3D:
	if _mind == null:
		return _nearest_player()

	# Typed explicitly, not inferred: `_mind` is a plain Node (see mind()
	# for why), so GDScript cannot work out what sense() returns and
	# refuses to compile the whole file — which took rcon.gd down with
	# it and would have taken the game down in play.
	var found: Node3D = _mind.sense(get_world_3d(), global_position,
			get_rid())

	if found != null:
		# Watch them. Everything it learns comes from this, and only
		# from things anyone standing there could see.
		_mind.watch(found, delta, global_position)

		# Commit to a plan for a while, then judge it by whether it
		# actually got closer, and pick again (STO-ENEMIES-047).
		_plan_timer -= delta
		if _plan_timer <= 0.0:
			var dist := global_position.distance_to(found.global_position)
			if _plan_started_at < INF:
				_mind.note_outcome(String(found.name), _mind.plan(),
						dist < _plan_started_at)
			_mind.choose_plan(String(found.name))
			_plan_timer = PLAN_TIME
			_plan_started_at = dist
	return found


## Practising its walk and noticing when it is getting nowhere. Called
## once per tick with how far it actually moved — distance covered, not
## speed asked for, because only the first cannot be faked by flailing.
func _think_about_moving(moved: float, delta: float, trying: bool) -> void:
	if _mind == null:
		return
	# Only while it is actually trying to walk. A creature cannot
	# practise walking while standing still — and letting it try meant a
	# stationary spider changed its stride every few seconds forever, so
	# its legs never came to rest and its idle read as a permanent
	# fidget.
	if trying:
		_mind.practise(moved, delta)
	_mind.note_progress(moved, delta, trying)
	# A damaged creature moves differently, not merely slower
	# (STO-ENEMIES-044). Handed to the body so the gait itself changes.
	if _body != null and _body.has_method("set_gait_scale"):
		_body.call("set_gait_scale", _mind.gait())


## The spider's mind, for tests and the debug overlay. Null for
## anything that has not got one.
##
## Typed as Node, not SpiderMind: a `class_name` is only resolvable
## once the project has been rescanned, and a headless `-s` test run
## does not rescan. Naming the class here made every script that
## depends on this one fail to compile in exactly the situation where
## it most needed to work.
func mind() -> Node:
	return _mind


# --- Taking you away (EPI-ENEMIES-SPIDER-TAKES-YOU) -------------------

## The pincer arms, or null for anything that has none. Every step of
## the taking sequence is gated on this, so a Walker can never do it.
func _pincer_arms() -> Node3D:
	if _body == null or not _body.has_method("pincers"):
		return null
	return _body.call("pincers") as Node3D


## How far the arms reach, read off the arms themselves. Rule 1 of this
## creature: derive it, never type it in — a bigger spider then starts
## reaching from further out with nothing re-tuned.
func _pincer_reach() -> float:
	var arms := _pincer_arms()
	if arms == null or not arms.has_method("reach"):
		return 0.0
	return float(arms.call("reach"))


## How close something has to be before it closes on them.
##
## Measured from the SURFACE of the creature, not its centre. Arm reach
## alone is not enough: this spider is nearly two metres across, so
## 55% of a 2.11 m reach came out at 1.16 m — shorter than the 1.33 m
## its own body forces every victim to stand at. It walked up to people
## and stood there, unable to grab anything, forever, and every check
## except the one that mattered still passed.
##
## Rule 1 of this creature, applied properly: derive it from the
## creature, INCLUDING the parts of the creature that get in the way.
func _grab_range() -> float:
	var body_radius := 0.4
	if _collider != null and _collider.shape is CapsuleShape3D:
		body_radius = (_collider.shape as CapsuleShape3D).radius
	return body_radius + _pincer_reach() * GRAB_FRACTION


## Drive the whole reach → catch → smash → drag → spike sequence.
##
## Returns true when this state machine owns the spider's movement for
## the frame, so the ordinary chase and attack code is skipped.
func _update_take(delta: float) -> bool:
	var arms := _pincer_arms()
	if arms == null or _dead:
		return false

	match _take:
		TAKE_NONE, TAKE_REACH:
			return _update_reach(arms, delta)
		TAKE_SMASH:
			return _update_smash(delta)
		TAKE_DRAG:
			return _update_drag(delta)
		TAKE_LEAVE:
			return _update_leave(delta)
	return false


## Idle and closing in: unfold the arms toward whoever is near enough,
## and take hold of them once they are well inside reach
## (STO-ENEMIES-048, then STO-ENEMIES-034).
func _update_reach(arms: Node3D, _delta: float) -> bool:
	var prey := _nearest_player()
	var reach := _pincer_reach()
	if prey == null or reach <= 0.0:
		_end_reach(arms)
		return false

	var to: Vector3 = prey.global_position - global_position
	if to.length() > reach + REACH_MARGIN:
		_end_reach(arms)
		return false

	# Reaching does NOT take over movement — it keeps walking at you
	# while the arms come out, which is what makes it frightening rather
	# than a creature that stops to pose.
	_take = TAKE_REACH
	arms.call("aim_at", prey.global_position + Vector3.UP * 0.8)
	arms.call("set_reach", 1.0)
	arms.call("set_jaw", 1.0)      # jaws open as it reaches

	# Close enough, and actually able to get at them? Take hold.
	if to.length() <= _grab_range() and _can_strike(prey, reach) \
			and prey.has_method("grabbed_by"):
		_seize(prey, arms)
	return false


## Stop reaching — but ONLY on the frame we actually stop.
##
## This used to run every frame while nobody was near, which meant the
## spider was continuously reasserting "arms in, jaws idle" and silently
## stamping on anything else that tried to pose the pincers. A creature
## should only speak when it has something to say.
func _end_reach(arms: Node3D) -> void:
	if _take != TAKE_REACH:
		return
	_take = TAKE_NONE
	arms.call("clear_aim")
	arms.call("set_reach", 0.0)
	arms.call("set_jaw", -1.0)     # back to the idle weave


## It has you. Shut the jaws and start the slam.
func _seize(prey: Node3D, arms: Node3D) -> void:
	if not bool(prey.call("grabbed_by", self)):
		return                      # already taken, or refusing to be
	_prey = prey
	_take = TAKE_SMASH
	_take_timer = SMASH_TIME
	_takes += 1
	arms.call("set_jaw", 0.0)       # clamped shut on you
	# Pick the destination NOW, while it still has hold: choosing on
	# arrival would mean a spider that grabs you and then thinks about
	# where to go, which reads as hesitation.
	_spike = Spike.nearest(self, global_position)
	DebugOverlay.log("enemy/combat", self, "%s: SEIZED %s (spike: %s)",
			[name, prey.name, _spike.name if _spike != null else "(none)"])


## The smash (STO-ENEMIES-034). One hard hit that puts you on the floor
## — which is exactly where you need to be, because you are dragged and
## never lifted.
func _update_smash(delta: float) -> bool:
	if not _holding():
		return false
	velocity.x = 0.0
	velocity.z = 0.0
	_take_timer -= delta
	# Held at the drag point throughout, so the slam visibly puts you
	# down on the ground rather than teleporting you there afterwards.
	_place_prey()
	if _take_timer <= 0.0:
		if _prey.has_method("smashed_down"):
			_prey.call("smashed_down", SMASH_DAMAGE)
		elif _prey.has_method("hurt_by_enemy"):
			_prey.call("hurt_by_enemy", SMASH_DAMAGE)
		DebugOverlay.log("enemy/combat", self, "%s: smashes %s down for %.0f",
				[name, _prey.name, SMASH_DAMAGE])
		if _spike == null:
			# Nowhere to put them. Let go rather than drag them forever.
			_drop_prey("no spike in the world")
			return false
		_take = TAKE_DRAG
	return true


## Dragging you to the spike. You stay on the floor the whole way.
func _update_drag(delta: float) -> bool:
	if not _holding():
		return false
	if _spike == null or not is_instance_valid(_spike):
		_drop_prey("spike vanished")
		return false

	var to: Vector3 = _spike.global_position - global_position
	to.y = 0.0
	if to.length() <= IMPALE_RANGE:
		_impale()
		return true

	_walk(to.normalized(), _move_speed() * DRAG_SPEED_SCALE)
	_place_prey()
	return true


## Put them on the spike and let go (STO-ENEMIES-034).
func _impale() -> void:
	var victim := _prey
	velocity.x = 0.0
	velocity.z = 0.0
	if victim != null and victim.has_method("impaled_on"):
		victim.call("impaled_on", _spike)
	DebugOverlay.log("enemy/combat", self, "%s: leaves %s on %s",
			[name, victim.name if victim != null else "(nobody)",
			_spike.name if _spike != null else "(nothing)"])
	_prey = null
	_take = TAKE_LEAVE
	_take_timer = LEAVE_TIME
	var arms := _pincer_arms()
	if arms != null:
		arms.call("clear_aim")
		arms.call("set_reach", 0.0)
		arms.call("set_jaw", -1.0)


## Walking away, having left you there. It deliberately does NOT hunt
## during this: the pause is the point of the whole story, and a spider
## that immediately turns round for someone else never lets the moment
## land.
func _update_leave(delta: float) -> bool:
	_take_timer -= delta
	if _take_timer <= 0.0:
		_take = TAKE_NONE
		return false
	var away := global_position - (_spike.global_position if _spike != null
			else global_position + Vector3.FORWARD)
	away.y = 0.0
	if away.length() < 0.01:
		away = -global_transform.basis.z
	_walk(away.normalized(), _move_speed() * 0.6)
	return true


## Walk in `dir` at `speed`, obeying the same obstacle rules the
## ordinary chase obeys.
##
## Every step of the taking sequence takes over movement, and the first
## version of each simply drove at its destination. The spider then
## walked STRAIGHT UP a ten-metre wall while carrying a victim, because
## taking over movement had quietly skipped every obstacle rule the
## creature already had. Nothing else in delve can climb a wall; a busy
## spider must not become the exception. Both places steer through here
## now, so there is one rule rather than three copies that can drift.
func _walk(dir: Vector3, speed: float) -> void:
	var go := dir
	if _skirting:
		go = _around(go, _block_normal)
	velocity.x = go.x * speed
	velocity.z = go.z * speed
	if _climbing:
		velocity.y = CLIMB_SPEED
	look_at(global_position + go, Vector3.UP)


## Still actually holding a live player?
##
## Distance is part of the answer. A grip that survives any separation
## is a bug waiting to happen: a player who zips away, respawns, or is
## moved for any reason would still be "held" by a spider on the far
## side of the map, and would be silently teleported back to it every
## frame. If they are not roughly where we put them, we are not holding
## them any more.
func _holding() -> bool:
	if _prey == null or not is_instance_valid(_prey):
		_drop_prey("prey gone")
		return false
	if global_position.distance_to(_prey.global_position) > LOST_GRIP:
		_drop_prey("they got away")
		return false
	return true


## Where a dragged player is held: on the floor, behind the spider.
##
## The floor height is found with a ray rather than taken from the
## spider's own position, because the spider's origin rides two metres
## up inside its legs — using it would carry you along in mid-air, which
## is the exact thing the operator ruled out.
func _place_prey() -> void:
	if _prey == null or not is_instance_valid(_prey):
		return
	var behind: Vector3 = global_position \
			+ global_transform.basis.z * DRAG_BEHIND
	var from_p := behind + Vector3.UP * 3.0
	var q := PhysicsRayQueryParameters3D.create(from_p,
			behind + Vector3.DOWN * 6.0)
	q.exclude = [get_rid(), _prey.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var ground: float = float(hit["position"].y) if not hit.is_empty() \
			else global_position.y
	if _prey.has_method("dragged_to"):
		_prey.call("dragged_to", Vector3(behind.x, ground + DRAG_HEIGHT,
				behind.z))


## Let go of whoever we have, for whatever reason.
func _drop_prey(why: String) -> void:
	if _prey != null and is_instance_valid(_prey) \
			and _prey.has_method("released"):
		_prey.call("released")
	if _prey != null:
		DebugOverlay.log("enemy/combat", self, "%s: lets go of %s (%s)",
				[name, _prey.name, why])
	_prey = null
	_spike = null
	_take = TAKE_NONE
	# Stop driving. Every taking state steers the creature itself, and
	# a climb sets an upward velocity that nothing else clears — letting
	# go while carrying someone up an obstacle otherwise left the spider
	# still travelling, coasting on a decision it had abandoned.
	velocity = Vector3.ZERO
	var arms := _pincer_arms()
	if arms != null:
		arms.call("clear_aim")
		arms.call("set_reach", 0.0)
		arms.call("set_jaw", -1.0)


# --- What tests and the rest of the game ask -------------------------

## Make it let go of whoever it has, right now.
##
## Public because two different things need it: a rescue
## (STO-ENEMIES-035) has to be able to break the grip, and any code that
## MOVES a spider — a test fixture, a teleport, a level change — must be
## able to reset it, because a creature that keeps hold of a victim it
## can no longer reach is in a state nothing else can reason about.
func let_go() -> void:
	if _take == TAKE_NONE:
		return
	_drop_prey("let go")


## How many players this creature has taken hold of.
func takes() -> int:
	return _takes


## Who it has hold of right now, or null.
func prey() -> Node3D:
	return _prey


## Which stage of the taking it is in, as a readable word.
func take_state() -> String:
	match _take:
		TAKE_REACH: return "reach"
		TAKE_SMASH: return "smash"
		TAKE_DRAG: return "drag"
		TAKE_LEAVE: return "leave"
	return "none"


## Can we hit `prey` from here — close enough, and nothing solid in
## between? (STO-ENEMIES-011)
##
## The wall check matters: without it an enemy stuck on the far side
## of a maze wall would keep clobbering you through it, which reads as
## the game cheating rather than as a fight.
func _can_strike(prey: Node3D, reach: float) -> bool:
	if prey == null or not is_instance_valid(prey):
		return false
	var to := prey.global_position - global_position
	if Vector2(to.x, to.z).length() > reach:
		return false
	if absf(to.y) > 2.0:      # far above or below us — not reachable
		return false
	# Chest height on both ends, so the ray doesn't clip the floor.
	var from_p := global_position + Vector3.UP * 1.0
	var to_p := prey.global_position + Vector3.UP * 1.0
	var q := PhysicsRayQueryParameters3D.create(from_p, to_p)
	# Everything in delve sits on collision layer 1 — world, players,
	# enemies and ragdoll parts alike — so a mask cannot separate "wall"
	# from "the very player we are aiming at". Exclude both ends and
	# judge what we hit by TYPE instead: only static geometry is a wall.
	q.exclude = [get_rid(), prey.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.get("collider") is StaticBody3D:
		DebugOverlay.log("enemy/combat", self, "%s: blocked by %s",
				[name, String((hit["collider"] as Node).name)])
		return false
	return true


## The wind-up has finished — actually hit them, if they are still there.
func _land_blow() -> void:
	var prey := _nearest_player()
	if prey == null or not _can_strike(prey, ATTACK_REACH):
		DebugOverlay.log("enemy/combat", self, "%s: swing missed", [name])
		return
	var dmg := attack_damage()
	if dmg <= 0.0:
		DebugOverlay.log("enemy/combat", self, "%s: swings harmlessly", [name])
		return
	_swings += 1
	DebugOverlay.draw_line3("enemy/hits", self,
			global_position + Vector3.UP, prey.global_position + Vector3.UP,
			Color.ORANGE_RED)
	DebugOverlay.log("enemy/combat", self, "%s: hits %s for %.0f",
			[name, prey.name, dmg])
	if prey.has_method("hurt_by_enemy"):
		prey.call("hurt_by_enemy", dmg)
	elif prey.has_method("take_damage"):
		prey.call("take_damage", dmg)


## How hard this enemy hits. A plain enemy hits for ATTACK_DAMAGE;
## STO-ENEMIES-015 reduces it as arms are torn off.
func attack_damage() -> float:
	match arms_left():
		2: return _kind_damage
		1: return _kind_damage * ONE_ARM_DAMAGE
		_: return 0.0   # no arms: it still chases, but it is harmless


# --- Limbs (EPI-ENEMIES-ENEMY-LIMBS) ----------------------------------

## Tear a limb off (STO-ENEMIES-012). Only works while ragdolled — a
## standing enemy keeps all its parts.
func tear_off_limb(limb: String) -> bool:
	if not LIMBS.has(limb) or _lost.has(limb):
		return false
	if _ragdoll == null:
		return false
	if not bool(_ragdoll.call("detach", LIMBS[limb])):
		return false
	_lost.append(limb)
	DebugOverlay.log("enemy/combat", self, "%s: lost its %s", [name, limb])
	Sounds.make(global_position, Sounds.RAGDOLL_LANDING)
	_on_limb_lost(limb)
	return true


## Which kind of creature this is.
func kind_id() -> String:
	return _kind_id


## Which limbs are gone.
func lost_limbs() -> Array:
	return _lost.duplicate()


func has_limb(limb: String) -> bool:
	return LIMBS.has(limb) and not _lost.has(limb)


## Legs still attached (STO-ENEMIES-014 reads this).
func legs_left() -> int:
	return (1 if has_limb("leg_l") else 0) + (1 if has_limb("leg_r") else 0)


## Arms still attached (STO-ENEMIES-015 reads this).
func arms_left() -> int:
	return (1 if has_limb("arm_l") else 0) + (1 if has_limb("arm_r") else 0)


## What losing a limb DOES.
func _on_limb_lost(limb: String) -> void:
	# Head off = dead on the spot, however much health is left
	# (STO-ENEMIES-013). This is the payoff for aiming high: a rifle
	# shot or a full-power whip to the head ends a fight outright.
	if limb == "head":
		DebugOverlay.log("enemy/combat", self, "%s: beheaded -> dead", [name])
		die()
		return
	# Both legs gone = dead (STO-ENEMIES-014). One leg is a limp, not a
	# kill — see _move_speed.
	if legs_left() == 0:
		DebugOverlay.log("enemy/combat", self, "%s: both legs gone -> dead",
				[name])
		die()


## How fast it can chase (STO-ENEMIES-014). Take a leg and it can only
## limp after you; take both and it is already dead.
func _move_speed() -> float:
	match legs_left():
		2: return _kind_speed
		1: return _kind_speed * ONE_LEG_SPEED
		_: return 0.0


## Which limb owns a ragdoll part, or "" if it is a core part.
func _limb_for_part(part_name: String) -> String:
	for limb in LIMBS:
		if LIMBS[limb] == part_name:
			return limb
	# Parts further down a limb count as that limb: hit a forearm and
	# you have hit the arm.
	match part_name:
		"ForearmL": return "arm_l"
		"ForearmR": return "arm_r"
		"ShinL": return "leg_l"
		"ShinR": return "leg_r"
	return ""


## Blows landed, for tests.
func swings() -> int:
	return _swings


## True while rearing back to strike — the telegraph window.
func is_winding_up() -> bool:
	return _windup > 0.0


## How high this creature can get a leg — its own body height.
##
## Deliberately measured from the creature rather than typed in as a
## number: make the spider taller and its reach follows, with nothing
## to re-tune (STO-ENEMIES-027).
func _clamber_reach() -> float:
	if _body != null and _body.has_method("body_height"):
		return maxf(float(_body.call("body_height")), 0.5)
	return CLAMBER_FALLBACK


## What is in the way, and can we get over it?
##
## Returns {} for clear ground, else {"normal": Vector3,
## "over": bool} — `over` true for a thing we can clamber, false for a
## wall we must go around.
##
## Only STATIC geometry counts; you cannot climb another creature.
func _probe_ahead(dir: Vector3) -> Dictionary:
	if dir.length() < 0.1:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	var space := get_world_3d().direct_space_state
	# Look LOW first. A single waist-high ray is a humanoid's idea of
	# "in the way" — on a spider three metres tall it sails clean over
	# every crate in the game, and the creature reports open ground
	# while walking into a box. Shin height finds the small things; the
	# higher ray is the backstop for anything the low one skims under.
	var hit: Dictionary = {}
	var from_p := global_position
	for h in [0.35, 0.9]:
		from_p = global_position + Vector3.UP * float(h)
		var q := PhysicsRayQueryParameters3D.create(from_p,
				from_p + dir * CLIMB_REACH)
		q.exclude = [get_rid()]
		var got := space.intersect_ray(q)
		if not got.is_empty() and got.get("collider") is StaticBody3D:
			hit = got
			break
	if hit.is_empty():
		return {}

	var normal: Vector3 = hit.get("normal", Vector3.ZERO)
	var reach := _clamber_reach()

	# Can we see its top? Drop a ray from just above our reach, a
	# little way INSIDE the obstacle's face. If the obstacle is short
	# the ray lands on top of it. If it towers over us the ray starts
	# buried inside solid rock and reports nothing — and that "nothing"
	# is exactly the answer we want, because a surface we cannot see
	# the top of is a wall.
	var probe: Vector3 = hit.get("position", from_p) + dir * 0.15
	probe.y = global_position.y + reach + 0.2
	var down := PhysicsRayQueryParameters3D.create(probe,
			probe + Vector3.DOWN * (reach + 0.9))
	down.exclude = [get_rid()]
	var top := space.intersect_ray(down)
	var can_get_over: bool = not top.is_empty() \
			and float(top["position"].y) <= global_position.y + reach

	DebugOverlay.log("enemy/ai", self, "%s: obstacle top=%s reach=%.2f -> %s",
			[name,
			"none" if top.is_empty() else "%.2f" % float(top["position"].y),
			reach, "clamber" if can_get_over else "go around"])
	return {"normal": normal, "over": can_get_over}


## Steer along the face of something too big to climb.
##
## The tangent — the way we wanted to go, with the part that pushes
## into the stone taken out. Square-on to a wall that tangent vanishes,
## and there is no answer in the geometry as to which way to turn; so
## pick a side from the creature's own name. Hashed rather than random
## so it is the same on every peer and the same every frame — a spider
## that re-rolled its choice would dither in place forever.
func _around(want: Vector3, normal: Vector3) -> Vector3:
	var n := Vector3(normal.x, 0.0, normal.z)
	if n.length() < 0.01:
		return want
	n = n.normalized()
	var tangent: Vector3 = want - n * want.dot(n)
	if tangent.length() < WALL_TANGENT_MIN:
		var side := 1.0 if (hash(name) % 2) == 0 else -1.0
		tangent = n.cross(Vector3.UP) * side
	# Lean a little off the wall so we skirt it instead of grinding.
	return (tangent.normalized() + n * 0.15).normalized()


## Is this creature getting over something right now?
func is_climbing() -> bool:
	return _climbing


## Is this creature being turned aside by something too big?
func is_skirting() -> bool:
	return _skirting


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
func apply_knockback(impulse: Vector3, hit_point := Vector3.INF) -> void:
	var dv := impulse / _mass
	# A very hard blow on a body that is already down tears the limb
	# it landed on clean off (STO-ENEMIES-012). Ragdolled only: a
	# standing enemy keeps all its parts.
	if _ragdoll != null and dv.length() >= DISMEMBER_DV \
			and hit_point.is_finite():
		var part_name: String = _ragdoll.call("nearest_part", hit_point)
		var limb := _limb_for_part(part_name)
		if limb != "":
			tear_off_limb(limb)
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
		# has_method, NOT just null: buckle_leg is a HUMANOID move and
		# a four-legged body does not have it. Calling it anyway threw
		# "Nonexistent function 'buckle_leg'", which halts the game in a
		# debug build — the crash the operator hit whenever a spider
		# took a medium hit. A creature on four legs has no single leg
		# to buckle, so it simply lurches instead.
		if _body != null and _body.has_method("buckle_leg"):
			# Slightly shorter than the stumble so the leg is back under
			# them just before steering returns (and so the two timers,
			# which tick in _process vs _physics_process, can't race).
			_body.call("buckle_leg", _stumble_leg, STUMBLE_TIME * 0.8,
					clampf(dv.length() / (KNOCKDOWN_DV * _stability), 0.4, 1.0))
		# A four-legged body has no single leg to buckle, so the hit
		# knocks the life out of ALL its limbs for a moment instead
		# (STO-ENEMIES-037). Same has_method guard and the same reason:
		# only the spider has floppy limbs to go limp.
		elif _body != null and _body.has_method("go_limp"):
			_body.call("go_limp", STUMBLE_TIME * 0.8)
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
	var hit_parts: Array = ["ShinL", "ShinR"] if swept else ["Torso", "Head"]
	if _kind_id != "walker":
		hit_parts = ["FLLower", "BRLower"] if swept else ["Block"]
	rag.call("launch", velocity, dv, hit_parts)
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
	# Torn-off limbs stay in the world when the body gets up
	# (STO-ENEMIES-012) — they belong to the floor now, not to us.
	_ragdoll.call("release_detached")
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
	if _dead:
		return          # a corpse cannot be killed twice (STO-ENEMIES-016)
	_health -= amount
	# No damage flash (STO-ENEMIES-007): the physical reaction (shove /
	# stumble / ragdoll) IS the hit feedback; the body keeps its tint.
	DebugOverlay.log("enemy/combat", self, "%s: -%.0f hp -> %.0f",
			[name, amount, maxf(_health, 0.0)])
	if _health <= 0.0:
		die()


## Die, and LEAVE A BODY (STO-ENEMIES-016).
##
## This used to free the ragdoll and then free the enemy, so a defeated
## enemy popped out of existence mid-fight. Everything delve has built
## for physical fighting — the Grabber's arms, the Runner's tail,
## throwing, dragging — stopped working the instant a thing died.
##
## Now the ragdoll stays as a corpse: still a real physics object, still
## shoveable, but no longer anything that chases, swings or stands up.
func die() -> void:
	if _dead:
		return
	_dead = true
	_health = 0.0
	_windup = 0.0
	DebugOverlay.log("enemy/combat", self, "%s: defeated", [name])
	if _ragdoll == null:
		# Killed while still on its feet — it needs a body to leave.
		_knockdown(Vector3(0.0, 1.0, 0.0), false)
	if _ragdoll == null:
		queue_free()      # body could not be built; nothing to leave
		return
	# It must never get back up.
	_downed = INF
	_held_ragdoll = false
	# Stop being a target for other enemies' AI, but STAY in the
	# "enemies" group so the tail and arms can still hit it about.
	set_deferred("collision_layer", 0)
	_reap_old_corpses()


func is_dead() -> bool:
	return _dead


## Keep the graveyard from growing forever. Corpses are real physics
## bodies — eleven of them each — so an endless pile would quietly
## strangle the frame rate.
func _reap_old_corpses() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var corpses: Array = []
	for c in parent.get_children():
		if c != self and c.has_method("is_dead") and bool(c.call("is_dead")):
			corpses.append(c)
	# Oldest first: children keep their spawn order.
	while corpses.size() >= MAX_CORPSES:
		var oldest: Node = corpses.pop_front()
		DebugOverlay.log("enemy/combat", self, "reaping old corpse %s",
				[oldest.name])
		if oldest.has_method("free_corpse"):
			oldest.call("free_corpse")


## Remove this corpse and its physics parts.
func free_corpse() -> void:
	if _ragdoll != null:
		_ragdoll.queue_free()
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
	return _max_health
